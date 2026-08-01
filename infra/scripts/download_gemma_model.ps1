# Download Gemma 4 E2B LiteRT-LM model (~2.6 GB) for on-device inference.
# Usage:
#   powershell -ExecutionPolicy Bypass -File infra/scripts/download_gemma_model.ps1
# Then push to device:
#   adb shell mkdir -p /sdcard/Android/data/pe.ayni.sos.citizen_app/files/models
#   adb push models/gemma-4-E2B-it.litertlm /sdcard/Android/data/pe.ayni.sos.citizen_app/files/models/

$ErrorActionPreference = "Stop"
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$destDir = Join-Path $root "models"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
$dest = Join-Path $destDir "gemma-4-E2B-it.litertlm"

$url = "https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm?download=true"

if (Test-Path $dest) {
  $size = (Get-Item $dest).Length
  if ($size -gt 1GB) {
    Write-Host "Model already present: $dest ($([math]::Round($size/1GB,2)) GB)"
    exit 0
  }
}

Write-Host "Downloading Gemma 4 E2B (~2.6 GB) to $dest ..."
Write-Host "URL: $url"
curl.exe -L --retry 3 --continue-at - -o $dest $url
Write-Host "Done: $((Get-Item $dest).Length) bytes"
