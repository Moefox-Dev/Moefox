# Builds a Moefox multi-locale package and applies Moefox-only l10n overlays.
#
# Notes:
# - Uses full compilation (not artifact builds) to enable custom EXE icon embedding.
# - See build/docs/locales.rst for multi-locale build documentation.
# - This script assumes you have a working MozillaBuild environment.
#
# Usage:
#   package-multi-locale.ps1           # Normal build (incremental)
#   package-multi-locale.ps1 -Clobber  # Clean build (recommended for releases)

param(
	[switch]$Clobber
)

$ErrorActionPreference = 'Stop'

$top = Resolve-Path -Path (Join-Path $PSScriptRoot '..\..')
Set-Location $top

$mach = Join-Path $top 'mach.ps1'

# Ensure l10n-central repository exists
function Ensure-L10nCentral {
	$mozbuildPath = $env:MOZBUILD_STATE_PATH
	if (-not $mozbuildPath) {
		$mozbuildPath = Join-Path $env:USERPROFILE '.mozbuild'
	}
	$l10nDir = Join-Path $mozbuildPath 'l10n-central'

	$gitDir = Join-Path $l10nDir '.git'
	if (Test-Path $gitDir) {
		Write-Host "[moefox] l10n-central exists at $l10nDir, pulling latest..."
		git -C $l10nDir pull --quiet
		return
	}

	Write-Host "[moefox] l10n-central not found. Cloning mozilla-l10n/firefox-l10n..."
	if (Test-Path $l10nDir) {
		Remove-Item -Path $l10nDir -Recurse -Force
	}
	git clone https://github.com/mozilla-l10n/firefox-l10n.git $l10nDir --depth 1
	if ($LASTEXITCODE -ne 0) {
		throw "[moefox] Failed to clone l10n-central repository"
	}
	Write-Host "[moefox] Successfully cloned l10n-central to $l10nDir"
}

function Invoke-Mach {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$MachArgs
	)

	& $mach @MachArgs
	if ($LASTEXITCODE -ne 0) {
		throw ("[moefox] mach failed (exit {0}): mach {1}" -f $LASTEXITCODE, ($MachArgs -join ' '))
	}
}

function Restore-EnvVar {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Name,
		[AllowNull()]
		[string]$PreviousValue,
		[bool]$HadPrevious
	)

	if (-not $HadPrevious) {
		Remove-Item -Path ("Env:{0}" -f $Name) -ErrorAction SilentlyContinue
		return
	}

	Set-Item -Path ("Env:{0}" -f $Name) -Value $PreviousValue
}

$previousMozconfig = $env:MOZCONFIG
$hadPreviousMozconfig = Test-Path Env:MOZCONFIG
$previousChromeMultilocale = $env:MOZ_CHROME_MULTILOCALE
$hadPreviousChromeMultilocale = Test-Path Env:MOZ_CHROME_MULTILOCALE
$previousPath = $env:PATH

# Add MozillaBuild msys2 bin to PATH for Unix commands (rm, cp, etc.)
# This is required for mozmake to find Unix utilities
# Try to resolve MozillaBuild path from environment or common install locations
$mozbuildPaths = @(
	"${env:ProgramFiles}\mozilla-build\msys2\usr\bin",
	"${env:ProgramFiles(x86)}\mozilla-build\msys2\usr\bin",
	"${env:LOCALAPPDATA}\Programs\mozilla-build\msys2\usr\bin"
)
$msysBin = $mozbuildPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($msysBin) {
	$env:PATH = "$msysBin;$env:PATH"
}

try {
	# Configure
	$env:MOZCONFIG = Join-Path $top 'mozconfig.multilocale'

# Locales to include (edit as needed)
$locales = @('en-US', 'de', 'fr', 'es-ES', 'ja', 'zh-CN', 'zh-TW', 'ru', 'ko')

Write-Host "[moefox] Using MOZCONFIG=$env:MOZCONFIG"
Write-Host "[moefox] Locales: $($locales -join ', ')"

# 0) Ensure l10n-central exists (required for non-English locales)
Write-Host "[moefox] Ensuring l10n-central repository is available..."
Ensure-L10nCentral

# 0.1) Optional: Clean build (recommended for releases to avoid stale artifacts)
if ($Clobber) {
	Write-Host "[moefox] Cleaning build directory (clobber)..."
	Invoke-Mach clobber
}

# 1) Configure the build environment
Invoke-Mach configure

# 2) Build from source (required for full branding customization)
# Note: Artifact builds are no longer used to enable custom EXE icons
Invoke-Mach build

# 4) Process chrome resources for all non-en-US locales
# (This is part of package-multi-locale, but we do it separately to insert overlay step)
$nonEnUSLocales = $locales | Where-Object { $_ -ne 'en-US' }
$env:MOZ_CHROME_MULTILOCALE = $nonEnUSLocales -join ' '

$objdir = Resolve-Path -Path 'obj-x86_64-pc-windows-msvc-multilocale'
$objdir = $objdir.Path

Write-Host "[moefox] Processing chrome resources for locales: $($nonEnUSLocales -join ', ')"
$chromeTargets = $nonEnUSLocales | ForEach-Object { "chrome-$_" }

# Use mozmake directly since mach doesn't expose _run_make
$mozbuildPath = if ($env:MOZBUILD_STATE_PATH) { $env:MOZBUILD_STATE_PATH } else { Join-Path $env:USERPROFILE '.mozbuild' }
$mozmake = Join-Path $mozbuildPath 'mozmake\mozmake.exe'
# Use .NET ProcessorCount (always a positive integer, unlike $env:NUMBER_OF_PROCESSORS which can be 0)
$jobs = [System.Environment]::ProcessorCount
if ($jobs -le 0) { $jobs = 8 }
& $mozmake -C $objdir "-j$jobs" -s @chromeTargets
if ($LASTEXITCODE -ne 0) {
	throw "[moefox] Failed to process chrome resources"
}

# 5) Repackage browser/app (required before final packaging)
Write-Host "[moefox] Repackaging browser..."
& $mozmake -C (Join-Path $objdir 'browser\app') "-j$jobs" -s -w tools
if ($LASTEXITCODE -ne 0) {
	throw "[moefox] Failed to repackage browser"
}

# 6) Apply Moefox-only overlay strings into packaged locale files
# CRITICAL: This must happen BEFORE `mach package` so overlays are included in installer
Write-Host "[moefox] Applying l10n overlays to $objdir ..."
$overlayArgs = @(
	'python',
	'tools\moefox\l10n_overlay.py',
	'--objdir',
	$objdir,
	'--locales'
) + $locales
Invoke-Mach @overlayArgs

# 7) Stage uBlock Origin extension into distribution/extensions
# This is done after build but before package so the extension is included in the installer
Write-Host "[moefox] Staging uBlock Origin extension..."
$stageExtScript = Join-Path $PSScriptRoot 'stage-extension.ps1'
& $stageExtScript -Extension ublock -ObjDir $objdir -StageToObjDir
if ($LASTEXITCODE -ne 0) {
	throw "[moefox] Failed to stage uBlock Origin extension"
}

# 7.1) Stage Bitwarden extension into distribution/extensions
Write-Host "[moefox] Staging Bitwarden extension..."
& $stageExtScript -Extension bitwarden -ObjDir $objdir -StageToObjDir
if ($LASTEXITCODE -ne 0) {
	throw "[moefox] Failed to stage Bitwarden extension"
}

# 7.2) Stage Firefox Multi-Account Containers extension into distribution/extensions
Write-Host "[moefox] Staging Firefox Multi-Account Containers extension..."
& $stageExtScript -Extension multi-account-containers -ObjDir $objdir -StageToObjDir
if ($LASTEXITCODE -ne 0) {
	throw "[moefox] Failed to stage Firefox Multi-Account Containers extension"
}

# 8) Generate the final package with installer
# Remove stale multilocale.txt to force regeneration
$multilocaleFile = Join-Path $objdir 'dist\bin\res\multilocale.txt'
if (Test-Path $multilocaleFile) {
	Remove-Item -Path $multilocaleFile -Force
}

Write-Host "[moefox] Creating final package..."
Invoke-Mach package

# 9) Rename packages from firefox-* to moefox-*
Write-Host "[moefox] Renaming packages from firefox-* to moefox-*..."
$distDir = Join-Path $objdir 'dist'
$appIni = Join-Path $objdir 'dist\bin\application.ini'
$version = (Get-Content $appIni | Select-String '^Version=').ToString().Split('=')[1].Trim()
$renames = @(
	"firefox-$version.en-US.win64.installer.exe",
	"firefox-$version.en-US.win64.zip",
	"firefox-$version.en-US.win64.txt"
)

foreach ($oldName in $renames) {
	$oldPath = Join-Path $distDir $oldName
	if (Test-Path $oldPath) {
		$newName = $oldName -replace '^firefox-', 'moefox-'
		$newPath = Join-Path $distDir $newName
		# Remove existing file if it exists
		if (Test-Path $newPath) {
			Remove-Item -Path $newPath -Force
		}
		Rename-Item -Path $oldPath -NewName $newName
		Write-Host "[moefox] Renamed: $oldName -> $newName"
	}
}

Write-Host "[moefox] Done."
}
finally {
	Restore-EnvVar -Name 'MOZCONFIG' -PreviousValue $previousMozconfig -HadPrevious $hadPreviousMozconfig
	Restore-EnvVar -Name 'MOZ_CHROME_MULTILOCALE' -PreviousValue $previousChromeMultilocale -HadPrevious $hadPreviousChromeMultilocale
	$env:PATH = $previousPath
}