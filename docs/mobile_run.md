# Run Ayni SOS Flutter apps (Windows)

## Prerequisite (once)
1. Open Windows Settings → System → For developers
2. Enable **Developer Mode** (required for Flutter plugin symlinks)
3. Restart the terminal after enabling

Flutter SDK expected at: `C:\FLUTTER\flutter`

## Start API
```powershell
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

## Citizen app (Windows desktop)
```powershell
$env:Path = "C:\FLUTTER\flutter\bin;$env:Path"
cd apps\citizen_app
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Rescuer app
```powershell
cd apps\rescuer_app
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Android phone (USB debugging)
```powershell
flutter devices
flutter run -d <device_id> --dart-define=API_BASE_URL=http://172.37.1.24:8000
```
Use your PC LAN IP and start the API with `--host 0.0.0.0`.

## Android emulator
```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
