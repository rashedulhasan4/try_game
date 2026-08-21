$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$OutputDir = Join-Path $ProjectDir "builds"
$OutputApk = Join-Path $OutputDir "empire-legacy-debug.apk"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$Godot = Get-Command godot -ErrorAction SilentlyContinue
if (-not $Godot) {
    $Godot = Get-Command godot4 -ErrorAction SilentlyContinue
}
if (-not $Godot) {
    throw "Godot 4 was not found. Install Godot and its Android export templates first."
}

& $Godot.Source --headless --path $ProjectDir --export-debug Android $OutputApk
Write-Host "APK created at: $OutputApk"

