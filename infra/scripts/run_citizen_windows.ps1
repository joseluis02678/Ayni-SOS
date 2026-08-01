# Requires Developer Mode enabled (ms-settings:developers)
$ErrorActionPreference = "Stop"
$env:Path = "C:\FLUTTER\flutter\bin;" + $env:Path
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path "$root\apps\citizen_app")) {
  $root = "C:\Users\Mateo\Desktop\Proyectos\Ayni SOS"
}

$api = if ($args.Count -gt 0) { $args[0] } else { "http://127.0.0.1:8000" }

Write-Host "Starting citizen_app → API $api"
Set-Location "$root\apps\citizen_app"
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=$api
