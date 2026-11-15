<#
.SYNOPSIS
  Remove the publicos_desktop sparse package identity registered by
  Register-Identity.ps1.

.DESCRIPTION
  Undoes the registration and deletes the staged package layout. The build
  output and the .exe are NOT touched -- the sparse package never contained
  them. After this, publicos.dev and publicos:// links go back to the browser.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$pkg = Get-AppxPackage -Name 'PublicOS.Desktop' -ErrorAction SilentlyContinue
if ($pkg) {
  Write-Host "Removing $($pkg.PackageFullName) ... " -NoNewline
  Remove-AppxPackage -Package $pkg.PackageFullName
  Write-Host 'ok' -ForegroundColor Green
} else {
  Write-Host 'Not registered - nothing to do.'
}

$stage = Join-Path $projectRoot 'build\windows\packaging_stage'
if (Test-Path $stage) {
  Remove-Item $stage -Recurse -Force
  Write-Host "Removed staged layout: $stage"
}

Write-Host 'The build output and the .exe were not touched.'
