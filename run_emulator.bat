@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server\ensure_current_server.ps1"
if errorlevel 1 exit /b 1
flutter run -d emulator-5554 --no-enable-impeller --enable-software-rendering --dart-define=PRODUCT_SEARCH_API_URL=http://10.0.2.2:8080
