<#
.SYNOPSIS
  Regenerate the sparse package's logo assets from windows/runner/resources/app_icon.ico.

.DESCRIPTION
  Run this whenever the app icon changes. It writes the QUALIFIED asset set
  MSIX expects, not just three plain PNGs.

  WHY THE QUALIFIERS MATTER:
  a plain `Square44x44Logo.png` is not enough. Windows' "select an app to open
  this link" chooser -- the exact dialog our universal link produces -- renders
  the app-list icon from the `targetsize-*` and `altform-unplated` variants.
  With only an unqualified PNG present it silently falls back to a GENERIC
  stock icon. The manifest still points at the
  bare `assets\Square44x44Logo.png`; Windows resolves the qualified siblings
  next to it by naming convention, so no manifest change is needed.

  `altform-unplated` = the icon drawn WITHOUT the coloured tile behind it.
  The chooser and the taskbar use the unplated form; Start uses the plated one.
  Our mark already carries its own dark background, so both are the same art.

  Uses System.Drawing (in-box) -- no Python, no packages.

.EXAMPLE
  .\Generate-Assets.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$packagingDir = $PSScriptRoot
$assetsDir    = Join-Path $packagingDir 'assets'
$icoPath      = Join-Path (Split-Path $packagingDir -Parent) 'runner\resources\app_icon.ico'

if (-not (Test-Path $icoPath)) { throw "Source icon not found: $icoPath" }
New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null

# Pull the largest USABLE frame out of the .ico so every downscale starts big.
#
# Why the loop: a modern .ico stores its 256px frame PNG-COMPRESSED, and
# System.Drawing's Icon.ToBitmap() cannot decode that -- it throws
# "Requested range extends past the end of the array". The smaller frames are
# plain BMP and load fine. So walk down until one works, and say which was used
# rather than silently producing a soft icon from a 32px source.
$src = $null
$srcIcon = $null

# Preferred source: the committed 256px master PNG. It exists precisely BECAUSE
# the .ico path below degrades badly -- every frame above 32px in Flutter's
# app_icon.ico is PNG-compressed and unreadable here, so the fallback silently
# produced 256px assets upscaled 8x from a 32px source. Regenerate the master
# with any tool that can read a PNG-compressed .ico frame when the icon changes.
$masterPath = Join-Path $packagingDir 'logo_master.png'
if (Test-Path $masterPath) {
  $src = New-Object System.Drawing.Bitmap($masterPath)
  Write-Host "Source: $masterPath  ($($src.Width)x$($src.Height))  [master PNG]"
}

if (-not $src) {
foreach ($frame in @(256, 128, 64, 48, 32)) {
  try {
    $candidateIcon = New-Object System.Drawing.Icon($icoPath, $frame, $frame)
    $src = $candidateIcon.ToBitmap()
    $srcIcon = $candidateIcon
    Write-Host "Source: $icoPath  (frame ${frame}px -> $($src.Width)x$($src.Height))"
    break
  } catch {
    Write-Host "  frame ${frame}px unreadable (PNG-compressed), trying smaller"
    if ($candidateIcon) { $candidateIcon.Dispose() }
  }
}
}
if (-not $src) { throw "No readable frame in $icoPath" }
if ($src.Width -lt 128) {
  Write-Warning "Largest readable frame is only $($src.Width)px - the 256px targetsize assets will be upscaled and soft."
}

function Write-Png([int]$size, [string]$name) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size)
  $g   = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.DrawImage($src, 0, 0, $size, $size)
  $g.Dispose()
  $path = Join-Path $assetsDir $name
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  return $path
}

$written = 0

# --- Square44x44Logo: the app-list / chooser / taskbar mark.
#     scale-* = display DPI. targetsize-* = a concrete pixel size the shell asks
#     for. _altform-unplated = no tile behind it. The chooser wants the last two.
Write-Png 44  'Square44x44Logo.png'            | Out-Null; $written++
foreach ($s in @(100,125,150,200,400)) {
  Write-Png ([math]::Round(44 * $s / 100)) "Square44x44Logo.scale-$s.png" | Out-Null; $written++
}
foreach ($t in @(16,24,32,48,256)) {
  Write-Png $t "Square44x44Logo.targetsize-$t.png"                  | Out-Null; $written++
  Write-Png $t "Square44x44Logo.targetsize-${t}_altform-unplated.png" | Out-Null; $written++
}

# --- Square150x150Logo: the Start tile.
Write-Png 150 'Square150x150Logo.png' | Out-Null; $written++
foreach ($s in @(100,125,150,200,400)) {
  Write-Png ([math]::Round(150 * $s / 100)) "Square150x150Logo.scale-$s.png" | Out-Null; $written++
}

# --- StoreLogo: listings and some shell surfaces.
Write-Png 50 'StoreLogo.png' | Out-Null; $written++
foreach ($s in @(100,200,400)) {
  Write-Png ([math]::Round(50 * $s / 100)) "StoreLogo.scale-$s.png" | Out-Null; $written++
}

$src.Dispose()
if ($srcIcon) { $srcIcon.Dispose() }   # null when the master PNG was used

Write-Host "Wrote $written assets to $assetsDir" -ForegroundColor Green
Write-Host 'Re-run Register-Identity.ps1 for the shell to pick them up.'
Write-Host 'The icon cache is sticky -- if the chooser still shows the old mark,'
Write-Host 'unregister, re-register, and open the link again.'
