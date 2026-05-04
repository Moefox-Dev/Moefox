#!/usr/bin/env powershell
# Moefox Build Helper - Unified build and package script
#
# Usage:
#   .\build-moefox.ps1              # Interactive mode (recommended)
#   .\build-moefox.ps1 -Dev         # Development build (mach build only)
#   .\build-moefox.ps1 -Dev -Clean  # Clean development build
#   .\build-moefox.ps1 -Release     # Full release build with multi-locale packaging
#   .\build-moefox.ps1 -Release -Clobber  # Clean release build

param(
    [switch]$Dev,         # Development build (mach build only, for testing)
    [switch]$Release,     # Release build (full multi-locale packaging)
    [switch]$Clean,       # For Dev mode: run clobber before build
    [switch]$Clobber,     # For Release mode: run clobber before build
    [switch]$Quick,       # Skip configure, only build
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$top = Resolve-Path -Path (Join-Path $scriptDir '..\..')
Set-Location $top

function Show-Help {
    @"
Moefox Build Helper
===================

Usage:
  .\tools\moefox\build-moefox.ps1              Interactive mode (recommended)
  .\tools\moefox\build-moefox.ps1 -Dev         Development build
  .\tools\moefox\build-moefox.ps1 -Release     Release build with packaging

Options:
  -Dev        Development build (mach build only, fast iteration)
              Use with -Clean for clean build, -Quick to skip configure
  
  -Release    Full release build with multi-locale packaging
              Use with -Clobber for clean build
  
  -Clean      (Dev mode) Run clobber before build
  -Clobber    (Release mode) Run clobber before build
  -Quick      Skip configure step (for incremental builds)
  -Help       Show this help message

Examples:
  # Interactive mode - guided menu
  .\tools\moefox\build-moefox.ps1

  # Quick dev iteration
  .\tools\moefox\build-moefox.ps1 -Dev -Quick

  # First time or after major changes
  .\tools\moefox\build-moefox.ps1 -Dev -Clean

  # Prepare release package
  .\tools\moefox\build-moefox.ps1 -Release -Clobber
"@
}

function Show-Banner {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "  Moefox Build Helper" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host ""
}

function Show-InteractiveMenu {
    Show-Banner
    
    Write-Host "Select build mode:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Dev Build (Quick)" -ForegroundColor Green
    Write-Host "      - Incremental build for development"
    Write-Host "      - Skips configure, fastest option"
    Write-Host "      - Use: mach run to test"
    Write-Host ""
    Write-Host "  [2] Dev Build (Full)" -ForegroundColor Green
    Write-Host "      - Full build with configure"
    Write-Host "      - Use after changing build config"
    Write-Host ""
    Write-Host "  [3] Dev Build (Clean)" -ForegroundColor Yellow
    Write-Host "      - Clobber + configure + build"
    Write-Host "      - Use for first build or major changes"
    Write-Host ""
    Write-Host "  [4] Release Build" -ForegroundColor Magenta
    Write-Host "      - Full multi-locale packaging"
    Write-Host "      - Creates installer and portable ZIP"
    Write-Host ""
    Write-Host "  [5] Release Build (Clean)" -ForegroundColor Magenta
    Write-Host "      - Clobber + full release build"
    Write-Host "      - Recommended for official releases"
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-5)"
    
    switch ($choice) {
        "1" { return @{ Mode = "Dev"; Quick = $true; Clean = $false } }
        "2" { return @{ Mode = "Dev"; Quick = $false; Clean = $false } }
        "3" { return @{ Mode = "Dev"; Quick = $false; Clean = $true } }
        "4" { return @{ Mode = "Release"; Clobber = $false } }
        "5" { return @{ Mode = "Release"; Clobber = $true } }
        "0" { exit 0 }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            return Show-InteractiveMenu
        }
    }
}

function Invoke-DevBuild {
    param(
        [bool]$DoClean = $false,
        [bool]$DoQuick = $false
    )
    
    Show-Banner
    Write-Host "Mode: Development Build" -ForegroundColor Green
    Write-Host ""
    
    $startTime = Get-Date
    
    # Step 1: Clobber (optional)
    if ($DoClean) {
        Write-Host "[1/3] Cleaning build directory (clobber)..." -ForegroundColor Cyan
        & ./mach.ps1 clobber
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: clobber failed" -ForegroundColor Red
            exit 1
        }
        Write-Host ""
    }
    
    # Step 2: Configure (unless Quick mode)
    if (-not $DoQuick) {
        Write-Host "[2/3] Configuring build environment..." -ForegroundColor Cyan
        & ./mach.ps1 configure
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: configure failed" -ForegroundColor Red
            exit 1
        }
        Write-Host ""
    }
    
    # Step 3: Build
    Write-Host "[3/3] Building Moefox..." -ForegroundColor Cyan
    $buildStart = Get-Date
    & ./mach.ps1 build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: build failed" -ForegroundColor Red
        exit 1
    }
    $buildTime = (Get-Date) - $buildStart
    
    # Summary
    $totalTime = (Get-Date) - $startTime
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Green
    Write-Host "  Build Complete!" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Green
    Write-Host ""
    Write-Host "Build time: $($buildTime.TotalMinutes.ToString('F1')) minutes"
    Write-Host "Total time: $($totalTime.TotalMinutes.ToString('F1')) minutes"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  - Test: ./mach run"
    Write-Host "  - Package: .\tools\moefox\build-moefox.ps1 -Release"
    Write-Host ""
}

function Invoke-ReleaseBuild {
    param(
        [bool]$DoClobber = $false
    )
    
    Show-Banner
    Write-Host "Mode: Release Build (Multi-locale)" -ForegroundColor Magenta
    Write-Host ""
    
    $packageScript = Join-Path $scriptDir 'package-multi-locale.ps1'
    
    if ($DoClobber) {
        Write-Host "Starting clean release build..." -ForegroundColor Yellow
        & $packageScript -Clobber
    } else {
        Write-Host "Starting release build..." -ForegroundColor Yellow
        & $packageScript
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Release build failed" -ForegroundColor Red
        exit 1
    }
}

# Main entry point
if ($Help) {
    Show-Help
    exit 0
}

# Determine mode
if ($Dev) {
    Invoke-DevBuild -DoClean $Clean -DoQuick $Quick
}
elseif ($Release) {
    Invoke-ReleaseBuild -DoClobber $Clobber
}
else {
    # Interactive mode
    $options = Show-InteractiveMenu
    
    if ($options.Mode -eq "Dev") {
        Invoke-DevBuild -DoClean $options.Clean -DoQuick $options.Quick
    }
    elseif ($options.Mode -eq "Release") {
        Invoke-ReleaseBuild -DoClobber $options.Clobber
    }
}
