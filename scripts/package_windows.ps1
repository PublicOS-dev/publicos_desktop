# Package a shareable Windows build: zip of the Release folder + the hand-built
# xmtp_plugin_native.dll (which NO Flutter build produces). Refuses to
# package without a release DLL: shipping without it = contacts load, messages
# never do.
#
# Usage (from the repo root):  powershell -File scripts/package_windows.ps1
#   -SkipBuild       reuse the existing Release folder
#   -AllowStaleDll   package even if the plugin source is newer than the DLL
#   -XmtpPluginRepo  path to the xmtp_plugin checkout (default: ..\xmtp_plugin,
#                    a sibling of this repo)
#   -UpdateBase URL  TEST ONLY: the app looks for updates at URL instead of the
#                    real release address. Such a kit is named -TESTBASE and the
#                    release signer refuses it.
#
# A built kit carries a build id (UTC yyyyMMddHHmm) so it can update itself
# (lib/utils/app_update.dart). Next to the dated zip the script writes
# dist\release_<build>\ with the zip under its fixed release name and a
# release.json; the release signer turns that into the update certificate.
#
# The zip is self-contained: the VC++ runtime DLLs are copied in app-local, so
# the recipient installs nothing. What cannot be zipped: a Windows Hello PIN
# (boot asks for it) and the Edge WebView2 Runtime (in-app browser).
param([switch]$SkipBuild, [switch]$AllowStaleDll, [string]$XmtpPluginRepo, [string]$UpdateBase)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
if (-not $XmtpPluginRepo) { $XmtpPluginRepo = Join-Path (Split-Path $root -Parent) 'xmtp_plugin' }

$rel = Join-Path $root 'build\windows\x64\runner\Release'
$plugin = $XmtpPluginRepo
$dll = Join-Path $plugin 'rust\target\release\xmtp_plugin_native.dll'

if (-not (Test-Path $dll)) {
  throw "Missing release DLL: $dll`nBuild it first: cd $plugin\rust; cargo build --release (release<->release, never mix with debug)."
}

# A DLL older than the Rust or the Dart bindings it was built from panics at
# the first XMTP call (FRB content hash) or ships old messaging behaviour.
$dllTime = (Get-Item $dll).LastWriteTime
$newer = @(Get-ChildItem -Recurse -File (Join-Path $plugin 'rust\src'), (Join-Path $plugin 'lib\src\rust')) +
         @(Get-Item (Join-Path $plugin 'rust\Cargo.toml'), (Join-Path $plugin 'rust\Cargo.lock')) |
         Where-Object { $_.LastWriteTime -gt $dllTime }
if ($newer -and -not $AllowStaleDll) {
  throw "Stale release DLL ($dllTime). Newer plugin files:`n  $(($newer | ForEach-Object { $_.FullName }) -join "`n  ")`nRebuild: cd $plugin\rust; cargo build --release   (or pass -AllowStaleDll)."
}

# The VC++ runtime ships app-local. Source: the redistributable folder of the
# newest MSVC toolset installed with Visual Studio on this box.
$crt = Get-ChildItem 'C:\Program Files\Microsoft Visual Studio\*\*\VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT' -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.Parent.Parent.Name -match '^\d+(\.\d+)+$' } |
  Sort-Object { [version]$_.Parent.Parent.Name } | Select-Object -Last 1
if (-not $crt) { throw 'No VC++ redistributable folder found (Visual Studio\...\VC\Redist\MSVC\<version>\x64\Microsoft.VC*.CRT).' }

if (-not $SkipBuild) {
  if (Get-Process publicos_desktop -ErrorAction SilentlyContinue) {
    throw 'publicos_desktop.exe is running. Close it first: a build rewrites the asset bundle a running debug app reads.'
  }
  $build = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmm')
  $pubVer = (Select-String -Path pubspec.yaml -Pattern '^version:\s*([^\s+]+)').Matches[0].Groups[1].Value
  $defines = @("--dart-define=PUBLICOS_BUILD=$build", "--dart-define=PUBLICOS_VERSION=$pubVer")
  if ($UpdateBase) { $defines += "--dart-define=PUBLICOS_UPDATE_BASE=$UpdateBase" }
  Write-Host "== flutter build windows --release (build $build)"
  flutter build windows --release @defines
  if ($LASTEXITCODE -ne 0) { throw 'flutter build failed' }
}
if (-not (Test-Path (Join-Path $rel 'publicos_desktop.exe'))) { throw "No release exe at $rel" }

Copy-Item $dll (Join-Path $rel 'xmtp_plugin_native.dll') -Force
Write-Host "== copied xmtp_plugin_native.dll ($([math]::Round((Get-Item $dll).Length/1MB)) MB)"

$ver = (Select-String -Path pubspec.yaml -Pattern '^version:\s*([^\s+]+)').Matches[0].Groups[1].Value
$sha = (git rev-parse --short HEAD 2>$null); if (-not $sha) { $sha = 'nogit' }
# Uncommitted edits (re-pointed chain pins, say) are in the
# build but not in that commit: mark the name so a bug report is not misread.
if (git status --porcelain 2>$null) { $sha = "$sha-dirty" }
if ($UpdateBase) { $sha = "$sha-TESTBASE" }
$name = "publicos_desktop_${ver}_win-x64_$(Get-Date -Format yyyyMMdd)_$sha"
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist $name
New-Item -ItemType Directory -Force $dist | Out-Null
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory $stage | Out-Null
Copy-Item (Join-Path $rel '*') $stage -Recurse -Force
Copy-Item (Join-Path $crt.FullName '*.dll') $stage -Force
Write-Host "== VC++ runtime app-local from $($crt.Parent.Parent.Name)"

@"
PublicOS Desktop (Windows x64) - alpha build $name

Run:  publicos_desktop.exe   (unzip first; keep every file in this folder together)

Nothing to install: the Visual C++ runtime, the video player and the
database libraries are all in this folder.

Your PC needs:
  - Windows 10 or 11, 64-bit.
  - A Windows Hello PIN (Settings > Accounts > Sign-in options). The app
    asks for it when it starts; without one it stops on "Could not start".
  - Microsoft Edge WebView2 Runtime, for pages that open inside the app.
    Windows 11 includes it and most Windows 10 PCs have it. If needed:
    https://developer.microsoft.com/microsoft-edge/webview2/

Notes:
  - Unsigned build: Windows SmartScreen may warn on first launch
    ("More info" -> "Run anyway").
  - Chain ID 4489.
  - The app offers its own updates: "Update available" in the status bar.
  - Your keys and data live under your Windows profile (%APPDATA%), not in
    this folder. Moving or replacing the folder keeps your account.
  - If it stops on "Could not start": open a Command Prompt in this folder,
    run publicos_desktop.exe from there, and send us what it prints.

Known in this build:
  - Your keys are stored encrypted by Windows, tied to your Windows user.
  - The app's local database is NOT encrypted yet: messages, contacts and
    cached posts on this PC can be read by anyone who can open your Windows
    user or your disk. Use it on a PC you trust.
  - To remove everything: delete this folder, then the folders
    %APPDATA%\dev.publicos\publicos_desktop and %APPDATA%\xmtp_plugin.
"@ | Out-File -Encoding utf8 (Join-Path $stage 'README.txt')

$zip = "$stage.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path $stage -DestinationPath $zip -CompressionLevel Optimal
Remove-Item -Recurse -Force $stage
Write-Host "== $zip ($([math]::Round((Get-Item $zip).Length/1MB)) MB)"

# The release folder: the same zip under the fixed name the updater asks for,
# plus the fields the signer turns into the certificate.
if ($build) {
  $release = Join-Path $root "dist\release_$build"
  if (Test-Path $release) { Remove-Item -Recurse -Force $release }
  New-Item -ItemType Directory $release | Out-Null
  Copy-Item $zip (Join-Path $release 'publicos_desktop_win-x64.zip')
  $fields = [ordered]@{
    app = 'publicos_desktop'; build = [long]$build; chain_id = 4489
    platform = 'win-x64'; version = $ver; zip_name = 'publicos_desktop_win-x64.zip'
    source_zip = (Split-Path $zip -Leaf)
  }
  if ($UpdateBase) { $fields.test_base = $UpdateBase }
  $json = $fields | ConvertTo-Json
  [IO.File]::WriteAllText((Join-Path $release 'release.json'), $json, (New-Object Text.UTF8Encoding $false))
  Write-Host "== release folder $release (build $build)"
}
