# Reset development profile for Moefox
# This removes the objdir/tmp/profile-default to force fresh default settings
param(
  [string]$ObjDir = ""
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ObjDir)) {
  $top = Resolve-Path -Path (Join-Path $PSScriptRoot '..\..')
  $candidates = @(
    (Join-Path $top 'obj-x86_64-pc-windows-msvc'),
    (Join-Path $top 'obj-x86_64-pc-windows-msvc-multilocale')
  ) | Where-Object { Test-Path $_ }

  if ($candidates.Count -gt 0) {
    $ObjDir = $candidates[0]
  } else {
    $fallback = Get-ChildItem -Path $top -Directory -Filter 'obj-*' -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($null -ne $fallback) {
      $ObjDir = $fallback.FullName
    }
  }
}

if ([string]::IsNullOrWhiteSpace($ObjDir)) {
  Write-Host "No objdir found. Pass -ObjDir <path> or run after creating an objdir." -ForegroundColor Red
  exit 1
}

$profilePath = Join-Path $ObjDir "tmp\profile-default"

if (Test-Path $profilePath) {
  Write-Host "Removing dev profile: $profilePath" -ForegroundColor Yellow
  Remove-Item -Path $profilePath -Recurse -Force
  Write-Host "Dev profile removed. Next 'mach run' will create a fresh profile with new defaults." -ForegroundColor Green
} else {
  Write-Host "No dev profile found at: $profilePath" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "You can now run: .\mach.ps1 run" -ForegroundColor Cyan
