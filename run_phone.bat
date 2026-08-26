@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=adb"

rem A phone can remain visible as "offline" after reconnecting the USB cable.
"%ADB%" reconnect offline >nul 2>&1
timeout /t 1 /nobreak >nul

set "DEVICE_ID=%~1"
if not defined DEVICE_ID (
  for /f "skip=1 tokens=1,2" %%A in ('"%ADB%" devices') do (
    if "%%B"=="device" (
      set "CANDIDATE=%%A"
      if /i not "!CANDIDATE:~0,9!"=="emulator-" if not defined DEVICE_ID set "DEVICE_ID=%%A"
    )
  )
)

if not defined DEVICE_ID (
  echo [ERROR] USB debugging is enabled, but no physical Android phone was found.
  echo Connect the phone, accept the USB debugging prompt, and run flutter devices.
  exit /b 1
)

powershell -NoProfile -Command "try { $null = Invoke-RestMethod -Uri 'http://127.0.0.1:8080/health' -TimeoutSec 2; exit 0 } catch { exit 1 }"
if errorlevel 1 (
  echo [ERROR] Product search server is not running on port 8080.
  echo Open another terminal and run:
  echo node --env-file=server\.env server\server.mjs
  exit /b 1
)

echo Using Android phone: %DEVICE_ID%
echo Connecting the phone to the local product search server...
"%ADB%" -s "%DEVICE_ID%" reverse tcp:8080 tcp:8080
if errorlevel 1 exit /b 1

flutter run -d "%DEVICE_ID%" --dart-define=PRODUCT_SEARCH_API_URL=http://127.0.0.1:8080
