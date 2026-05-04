# Moefox Extension Staging Script
# Downloads an extension XPI from AMO (or custom URL) and stages it into
# distribution/extensions for non-intrusive sideloading.
#
# Usage:
#   # Stage a known preset extension to objdir (auto-detect)
#   .\stage-extension.ps1 -Extension ublock
#   .\stage-extension.ps1 -Extension bitwarden
#   .\stage-extension.ps1 -Extension multi-account-containers
#
#   # Stage a custom extension by URL (addon id parsed from manifest.json)
#   .\stage-extension.ps1 -Extension custom -Url "https://example.com/foo.xpi"
#
#   # Stage to source directory (for dev/testing)
#   .\stage-extension.ps1 -Extension ublock -StageToSourceDir
#
#   # Explicitly specify objdir
#   .\stage-extension.ps1 -Extension ublock -ObjDir "path\to\objdir"

param(
  [Parameter(Mandatory = $true)]
  [string]$Extension,

  [string]$TopSrcDir = (Resolve-Path "$PSScriptRoot\..\..").Path,
  [string]$ObjDir = "",
  [switch]$StageToObjDir,
  [switch]$StageToSourceDir,
  [string]$Url = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---- Known extension presets ----
$presets = @{
  'ublock' = @{
    Url        = 'https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi'
    AddonId    = 'uBlock0@raymondhill.net'
    ParseId    = $false
  }
  'bitwarden' = @{
    Url        = 'https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi'
    AddonId    = ''
    ParseId    = $true
  }
  'multi-account-containers' = @{
    Url        = 'https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi'
    AddonId    = ''
    ParseId    = $true
  }
}

# ---- Resolve extension config ----
if ($Extension -eq 'custom') {
  if ([string]::IsNullOrWhiteSpace($Url)) {
    throw "-Url is required when Extension='custom'"
  }
  $extConfig = @{ Url = $Url; AddonId = ''; ParseId = $true }
} elseif ($presets.ContainsKey($Extension)) {
  $extConfig = $presets[$Extension]
} else {
  throw "Unknown extension preset: '$Extension'. Valid presets: $($presets.Keys -join ', '), or use 'custom' with -Url."
}

$downloadUrl = $extConfig.Url
$addonId     = $extConfig.AddonId
$parseId     = $extConfig.ParseId

# ---- Helpers ----

function Get-DefaultObjDir([string]$Top) {
  $candidates = @(
    (Join-Path $Top 'obj-x86_64-pc-windows-msvc'),
    (Join-Path $Top 'obj-x86_64-pc-windows-msvc-multilocale')
  ) | Where-Object { Test-Path $_ }

  if ($candidates.Count -gt 0) {
    return $candidates[0]
  }

  $fallback = Get-ChildItem -Path $Top -Directory -Filter 'obj-*' -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if ($null -ne $fallback) {
    return $fallback.FullName
  }

  return ''
}

function Get-AddonIdFromXpi([string]$XpiPath) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem

  $archive = $null
  $stream  = $null
  $reader  = $null
  try {
    $archive = [System.IO.Compression.ZipFile]::OpenRead($XpiPath)
    $entry = $archive.GetEntry('manifest.json')
    if ($null -eq $entry) {
      throw "manifest.json not found in XPI"
    }

    $stream = $entry.Open()
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8, $true)
    $manifestJson = $reader.ReadToEnd()
    $manifest = $manifestJson | ConvertFrom-Json

    $id = $null
    if ($null -ne $manifest.browser_specific_settings -and $null -ne $manifest.browser_specific_settings.gecko) {
      $id = $manifest.browser_specific_settings.gecko.id
    }
    if ([string]::IsNullOrWhiteSpace($id) -and $null -ne $manifest.applications -and $null -ne $manifest.applications.gecko) {
      $id = $manifest.applications.gecko.id
    }

    if ([string]::IsNullOrWhiteSpace($id)) {
      throw "Failed to read add-on id from manifest.json (applications.gecko.id / browser_specific_settings.gecko.id)"
    }

    return $id
  }
  finally {
    if ($null -ne $reader)  { $reader.Dispose() }
    if ($null -ne $stream)  { $stream.Dispose() }
    if ($null -ne $archive) { $archive.Dispose() }
  }
}

function Stage-ExtensionFile([string]$XpiPath, [string]$DstDir) {
  New-Item -ItemType Directory -Path $DstDir -Force | Out-Null
  $dstFile = Join-Path $DstDir "$addonId.xpi"
  Write-Host "Staging extension -> $dstFile"
  Copy-Item -Path $XpiPath -Destination $dstFile -Force
}

# ---- Resolve objdir ----
if ([string]::IsNullOrWhiteSpace($ObjDir)) {
  $ObjDir = Get-DefaultObjDir -Top $TopSrcDir
}

if (-not $StageToObjDir -and -not $StageToSourceDir) {
  $StageToObjDir = $true
}

# ---- Download ----
$tempoSuffix = if ($Extension -eq 'custom') { [Guid]::NewGuid().ToString('N') } else { $Extension }
$tempXpi = Join-Path $env:TEMP ("moefox-ext-" + $tempoSuffix + '.xpi')

try {
  Write-Host "Downloading extension from $downloadUrl -> $tempXpi"
  Invoke-WebRequest -Uri $downloadUrl -OutFile $tempXpi -UseBasicParsing

  # Resolve addon id if needed
  if ($parseId) {
    $addonId = Get-AddonIdFromXpi -XpiPath $tempXpi
    Write-Host "Parsed addon id: $addonId"
  }

  # Stage to source dir
  if ($StageToSourceDir) {
    $dstDir = Join-Path $TopSrcDir 'browser\app\distribution\extensions'
    Stage-ExtensionFile -XpiPath $tempXpi -DstDir $dstDir
  }

  # Stage to objdir
  if ($StageToObjDir) {
    if ([string]::IsNullOrWhiteSpace($ObjDir)) {
      throw "ObjDir not found. Pass -ObjDir <path> or run after creating an objdir."
    }

    $dstDir = Join-Path $ObjDir 'dist\bin\distribution\extensions'
    Stage-ExtensionFile -XpiPath $tempXpi -DstDir $dstDir
  }
}
finally {
  Remove-Item -Path $tempXpi -Force -ErrorAction SilentlyContinue
}

Write-Host 'Done.'
