@echo off
REM Build SkipQ  for Android
cd /d "%~dp0"
echo.
echo === Building SkipQ  ===
echo.
flutter pub get
if errorlevel 1 goto fail
REM Regenerate SkipQ logo icons if assets/images/logo-app-icon.png changed
dart run flutter_launcher_icons
if errorlevel 1 goto fail
flutter build  --release --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
if errorlevel 1 goto fail
echo.
echo SUCCESS!  is here:
echo %cd%\build\app\outputs\flutter-\app-release.
explorer build\app\outputs\flutter-
goto end

:fail
echo.
echo Build failed. Read START_HERE.md for help.
pause
exit /b 1

:end
pause
