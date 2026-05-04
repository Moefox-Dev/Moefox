# Clean all Moefox user data and settings
#
# This script removes all Moefox-related data from the user's machine,
# including profiles, caches, and registry entries. Use this to ensure
# a completely clean state before reinstalling.
#
# Usage:
#   clean-user-data.ps1        # Interactive mode with confirmation
#   clean-user-data.ps1 -Force # Skip confirmation prompts

param(
	[switch]$Force
)

$ErrorActionPreference = 'Continue'

# Moefox profile and data paths
# Note: Moefox currently uses Mozilla\Firefox paths (MOZ_APP_PROFILE not configured)
# This will clean ALL Firefox/Moefox data under Mozilla directory
$paths = @(
	# Main profile directory (roaming) - contains profiles, bookmarks, history, etc.
	"$env:APPDATA\Mozilla\Firefox",
	
	# Local profile data (non-roaming) - contains cache, etc.
	"$env:LOCALAPPDATA\Mozilla\Firefox",
	
	# Extensions directory
	"$env:APPDATA\Mozilla\Extensions",
	
	# Additional Mozilla directories
	"$env:LOCALAPPDATA\Mozilla",
	"$env:APPDATA\Mozilla"
)

# Registry paths to clean
$registryPaths = @(
	"HKCU:\Software\Mozilla",
	"HKCU:\Software\Classes\FirefoxHTML*",
	"HKCU:\Software\Classes\FirefoxURL*"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Moefox User Data Cleanup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Moefox is running
$moefoxProcesses = Get-Process -Name "firefox" -ErrorAction SilentlyContinue | 
	Where-Object { $_.Path -like "*Moefox*" }

if ($moefoxProcesses) {
	Write-Host "WARNING: Moefox is currently running!" -ForegroundColor Yellow
	Write-Host "The following processes will be terminated:" -ForegroundColor Yellow
	$moefoxProcesses | ForEach-Object { 
		Write-Host "  - PID $($_.Id): $($_.Path)" -ForegroundColor Yellow
	}
	Write-Host ""
	
	if (-not $Force) {
		$response = Read-Host "Do you want to terminate these processes? (y/N)"
		if ($response -ne 'y' -and $response -ne 'Y') {
			Write-Host "Aborted. Please close Moefox and run this script again." -ForegroundColor Red
			exit 1
		}
	}
	
	Write-Host "Terminating Moefox processes..." -ForegroundColor Yellow
	$moefoxProcesses | ForEach-Object {
		Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
	}
	Start-Sleep -Seconds 2
}

# Show what will be deleted
Write-Host "The following locations will be cleaned:" -ForegroundColor Yellow
Write-Host ""
Write-Host "File system paths:" -ForegroundColor Cyan
foreach ($path in $paths) {
	if (Test-Path $path) {
		$size = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
			Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
		$sizeStr = if ($size) { " ({0:N2} MB)" -f ($size / 1MB) } else { " (size unknown)" }
		Write-Host "  [EXISTS] $path$sizeStr" -ForegroundColor Green
	} else {
		Write-Host "  [NOT FOUND] $path" -ForegroundColor Gray
	}
}

Write-Host ""
Write-Host "Registry paths:" -ForegroundColor Cyan
foreach ($regPath in $registryPaths) {
	if (Test-Path $regPath) {
		Write-Host "  [EXISTS] $regPath" -ForegroundColor Green
	} else {
		Write-Host "  [NOT FOUND] $regPath" -ForegroundColor Gray
	}
}

Write-Host ""
Write-Host "This will permanently delete all Moefox user data, including:" -ForegroundColor Red
Write-Host "  - All browser profiles and settings" -ForegroundColor Red
Write-Host "  - Browsing history, bookmarks, and passwords" -ForegroundColor Red
Write-Host "  - Installed extensions and themes" -ForegroundColor Red
Write-Host "  - Cache and temporary files" -ForegroundColor Red
Write-Host "  - Registry entries" -ForegroundColor Red
Write-Host ""

if (-not $Force) {
	$response = Read-Host "Are you sure you want to continue? Type 'DELETE' to confirm"
	if ($response -ne 'DELETE') {
		Write-Host "Aborted by user." -ForegroundColor Yellow
		exit 0
	}
}

Write-Host ""
Write-Host "Starting cleanup..." -ForegroundColor Green
Write-Host ""

$deletedCount = 0
$failedCount = 0

# Clean file system paths
foreach ($path in $paths) {
	if (Test-Path $path) {
		Write-Host "Removing: $path" -ForegroundColor Yellow
		try {
			Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
			Write-Host "  SUCCESS" -ForegroundColor Green
			$deletedCount++
		} catch {
			Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
			$failedCount++
		}
	}
}

# Clean registry paths
foreach ($regPath in $registryPaths) {
	if (Test-Path $regPath) {
		Write-Host "Removing registry: $regPath" -ForegroundColor Yellow
		try {
			Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
			Write-Host "  SUCCESS" -ForegroundColor Green
			$deletedCount++
		} catch {
			Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
			$failedCount++
		}
	}
}

# Additional cleanup: Windows Start Menu shortcuts
$startMenuPaths = @(
	"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Moefox.lnk",
	"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Moefox",
	"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Firefox.lnk",
	"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Moefox.lnk",
	"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Moefox"
)

foreach ($shortcut in $startMenuPaths) {
	if (Test-Path $shortcut) {
		Write-Host "Removing shortcut: $shortcut" -ForegroundColor Yellow
		try {
			Remove-Item -Path $shortcut -Recurse -Force -ErrorAction Stop
			Write-Host "  SUCCESS" -ForegroundColor Green
			$deletedCount++
		} catch {
			Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
			$failedCount++
		}
	}
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cleanup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Removed: $deletedCount items" -ForegroundColor Green
if ($failedCount -gt 0) {
	Write-Host "Failed:  $failedCount items" -ForegroundColor Red
	Write-Host ""
	Write-Host "Some items could not be removed. This may be due to:" -ForegroundColor Yellow
	Write-Host "  - Insufficient permissions (try running as Administrator)" -ForegroundColor Yellow
	Write-Host "  - Files in use by another process" -ForegroundColor Yellow
	exit 1
} else {
	Write-Host ""
	Write-Host "All Moefox user data has been successfully removed." -ForegroundColor Green
	Write-Host "You can now reinstall Moefox with a clean slate." -ForegroundColor Green
	exit 0
}
