@echo off
setlocal

cd /d "%~dp0"

echo ========================================
echo NZ Vege Garden - Flutter Runner
echo Project: %CD%
echo ========================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: Flutter was not found in PATH.
  echo Open Android Studio and check Flutter SDK settings.
  pause
  exit /b 1
)

echo Getting Flutter packages...
flutter pub get
if errorlevel 1 (
  echo.
  echo ERROR: flutter pub get failed.
  pause
  exit /b 1
)

echo.
echo Select run target:
echo.
echo   1. Chrome
echo   2. Android device / emulator
echo   3. Show Flutter devices
echo.
set /p target="Enter choice [1-3]: "

if "%target%"=="1" goto chrome
if "%target%"=="2" goto android
if "%target%"=="3" goto devices

echo Invalid choice.
pause
exit /b 1

:chrome
echo.
echo Running on Chrome...
flutter run -d chrome
goto end

:android
echo.
echo Available devices:
flutter devices
echo.
echo Running on Android. Start an emulator first if no Android device appears.
flutter run
goto end

:devices
echo.
flutter devices
goto end

:end
echo.
pause
endlocal
