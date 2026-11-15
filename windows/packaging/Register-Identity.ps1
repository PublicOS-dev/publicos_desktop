<#
.SYNOPSIS
  Give the local publicos_desktop build a package identity, so Windows will
  hand it https://publicos.dev links (windows.appUriHandler) and publicos://
  links (windows.protocol).

.DESCRIPTION
  Registers windows/packaging/AppxManifest.xml as a SPARSE package
  ("packaging with external location"): the .exe is NOT copied anywhere, it
  keeps running from the Flutter build output, and this only grants it the
  package identity that appUriHandler requires.

  Unsigned and non-admin, which works because Developer Mode is on. That is a
  DEV path on purpose -- shipping this to users needs a signed .msix, and the
  Publisher below must then match the signing certificate subject exactly.

  Registering does not modify the build. Unregistering leaves no trace.

.PARAMETER BuildDir
  The folder holding publicos_desktop.exe. Defaults to the Release build.

.PARAMETER Debug
  Use the Debug build output instead of Release.

.EXAMPLE
  .\Register-Identity.ps1
  .\Register-Identity.ps1 -Debug
#>
[CmdletBinding()]
param(
  [string]$BuildDir,
  [switch]$DebugBuild
)

$ErrorActionPreference = 'Stop'

$packagingDir = $PSScriptRoot
$projectRoot  = Split-Path (Split-Path $packagingDir -Parent) -Parent

if (-not $BuildDir) {
  $flavor  = if ($DebugBuild) { 'Debug' } else { 'Release' }
  $BuildDir = Join-Path $projectRoot "build\windows\x64\runner\$flavor"
}

Write-Host ''
Write-Host 'PublicOS desktop - register package identity' -ForegroundColor Cyan
Write-Host ('-' * 52)

# --- Preconditions, each failing with the actual fix rather than a stack trace.

$devMode = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
             -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue
if (-not $devMode -or $devMode.AllowDevelopmentWithoutDevLicense -ne 1) {
  throw "Developer Mode is OFF. Unsigned registration needs it: Settings > System > For developers > Developer Mode."
}
Write-Host '  Developer Mode      : on'

$exe = Join-Path $BuildDir 'publicos_desktop.exe'
if (-not (Test-Path $exe)) {
  throw "No build at`n    $exe`nRun 'flutter build windows' (or pass -BuildDir / -DebugBuild) first."
}
Write-Host "  Build               : $BuildDir"

$manifestSource = Join-Path $packagingDir 'AppxManifest.xml'
if (-not (Test-Path $manifestSource)) { throw "Missing $manifestSource" }

# --- The layout Windows registers from.
#
# The manifest and its logos must sit in ONE folder that Windows can read, and
# that folder must not be the build output (a `flutter clean` would wipe it).
# So the package layout is staged beside the build, and ExternalLocation points
# at the build itself. Two directories, deliberately.
$stage = Join-Path $projectRoot 'build\windows\packaging_stage'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Copy-Item $manifestSource (Join-Path $stage 'AppxManifest.xml')
Copy-Item (Join-Path $packagingDir 'assets') $stage -Recurse
Write-Host "  Package stage       : $stage"

# --- Remove any previous registration so this is idempotent.
$existing = Get-AppxPackage -Name 'PublicOS.Desktop' -ErrorAction SilentlyContinue
if ($existing) {
  Write-Host "  Existing            : $($existing.PackageFullName) - removing"
  Remove-AppxPackage -Package $existing.PackageFullName
}

# --- Register.
Write-Host '  Registering         : ' -NoNewline
Add-AppxPackage -Register (Join-Path $stage 'AppxManifest.xml') -ExternalLocation $BuildDir
Write-Host 'ok' -ForegroundColor Green

$pkg = Get-AppxPackage -Name 'PublicOS.Desktop'
if (-not $pkg) { throw 'Registration reported success but the package is not listed.' }

Write-Host ''
Write-Host 'Registered.' -ForegroundColor Green
Write-Host "  PackageFullName     : $($pkg.PackageFullName)"
Write-Host "  PackageFamilyName   : $($pkg.PackageFamilyName)" -ForegroundColor Yellow
Write-Host ''
Write-Host '  ^ that PackageFamilyName is what publicos.dev/.well-known/windows-app-web-link'
Write-Host '    must carry before this works for anyone but us.'
Write-Host ''
Write-Host 'Try it (close the app first - this proves COLD start only):' -ForegroundColor Cyan
Write-Host '    Win+R  ->  https://publicos.dev/publicosAddress/0x0000000000000000000000000000000000000000/chat/support'
Write-Host '    Win+R  ->  publicos://profile/0x0000000000000000000000000000000000000000'
Write-Host ''
Write-Host '  A box should appear with the URL, and it is appended to:'
Write-Host "    $env:LOCALAPPDATA\PublicOS\deeplink.log"
Write-Host ''
Write-Host '  Remember: it will NOT fire from Chrome/Edge/Firefox. That is by design,'
Write-Host '  not a bug in this setup.'
Write-Host ''
