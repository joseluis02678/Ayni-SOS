# Run Ayni SOS mobile (Android-first)

## Prerequisite (once)
1. Open Windows Settings → System → For developers → enable **Developer Mode**
2. Flutter SDK: `C:\FLUTTER\flutter`
3. Android device: USB debugging ON, or install APK from `dist/android/`
4. Copy `android/key.properties.example` → `android/key.properties` (both apps) if missing
5. Release keystore lives in `signing/ayni-release.jks` (gitignored)

## Start API (LAN — required for physical phone)
```powershell
cd backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```
Use your PC Wi‑Fi IP (example `172.37.1.24`), same network as the phone.

## Build signed release APKs
```powershell
powershell -ExecutionPolicy Bypass -File infra/scripts/build_android_apks.ps1 -ApiBaseUrl http://172.37.1.24:8000
```
Outputs:
- `dist/android/ayni-sos-citizen-release.apk`
- `dist/android/ayni-sos-rescuer-release.apk`

Install:
```powershell
adb install -r dist/android/ayni-sos-citizen-release.apk
adb install -r dist/android/ayni-sos-rescuer-release.apk
```

## Flutter run (USB debugging)
```powershell
$env:Path = "C:\FLUTTER\flutter\bin;$env:Path"
flutter devices
cd apps\citizen_app
flutter run -d <device_id> --dart-define=API_BASE_URL=http://172.37.1.24:8000
```

Emulator API host: `http://10.0.2.2:8000`

## Gemma 4 / LiteRT (optional on-device model)
Without the `.litertlm` file the citizen app uses **HeuristicRuntime** (safe fallback).

1. Download (~2.6 GB):
```powershell
powershell -ExecutionPolicy Bypass -File infra/scripts/download_gemma_model.ps1
```
2. Push into app documents (after first install):
```powershell
adb shell mkdir -p /sdcard/Android/data/pe.ayni.sos.citizen_app/files/models
adb push models/gemma-4-E2B-it.litertlm /sdcard/Android/data/pe.ayni.sos.citizen_app/files/models/
```
Or set `--dart-define=GEMMA_MODEL_PATH=/absolute/path/on/device.litertlm`

Force heuristic even if model exists: `--dart-define=FORCE_HEURISTIC_AI=true`

Citizen app requires **Android 12+ (API 31)** for LiteRT-LM.

## Media upload
After HTTP sync, evidence files under app documents are uploaded to  
`POST /api/v1/sync/media/{report_id}` (multipart `file` + `sha256`).

## Windows desktop (optional)
```powershell
cd apps\citizen_app
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
```
