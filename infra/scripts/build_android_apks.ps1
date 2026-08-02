# Build signed release APKs for citizen + rescuer.
# Usage:
#   powershell -ExecutionPolicy Bypass -File infra/scripts/build_android_apks.ps1 [-ApiBaseUrl http://172.37.1.24:8000]

param(
  [string]$ApiBaseUrl = "http://192.168.1.37:8000"
)

$ErrorActionPreference = "Stop"
$env:Path = "C:\FLUTTER\flutter\bin;" + $env:Path
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out = Join-Path $root "dist\android"
New-Item -ItemType Directory -Force -Path $out | Out-Null

$define = "--dart-define=API_BASE_URL=$ApiBaseUrl"

Write-Host "Building citizen_app release APK (API=$ApiBaseUrl)..."
Push-Location (Join-Path $root "apps\citizen_app")
flutter pub get
flutter build apk --release $define --dart-define=FORCE_HEURISTIC_AI=true
$citizenApk = Get-ChildItem "build\app\outputs\flutter-apk\*.apk" | Select-Object -First 1
Copy-Item $citizenApk.FullName (Join-Path $out "ayni-sos-citizen-release.apk") -Force
Pop-Location

Write-Host "Building rescuer_app release APK..."
Push-Location (Join-Path $root "apps\rescuer_app")
flutter pub get
flutter build apk --release $define
$rescuerApk = Get-ChildItem "build\app\outputs\flutter-apk\*.apk" | Select-Object -First 1
Copy-Item $rescuerApk.FullName (Join-Path $out "ayni-sos-rescuer-release.apk") -Force
Pop-Location

Write-Host "APKs ready in $out"
Get-ChildItem $out | Format-Table Name, Length
