@echo off
title SENTINEL-Ward Launcher
echo ========================================================
echo   Starting SENTINEL-Ward Telemetry System
echo ========================================================
echo.

cd /d "%~dp0"

:: 1. Launch Backend Server in a dedicated Command Prompt window
echo [1/2] Launching Backend Server (SQLite + Socket.IO + REST on Port 3000)...
start "SENTINEL-Ward Backend Server" cmd /k "cd /d "%~dp0backend" && npm start"

:: Wait 3 seconds to ensure backend starts and initializes database
timeout /t 3 /nobreak >nul

:: 2. Launch Flutter Web Application on Chrome
echo [2/2] Launching Flutter Application on Chrome...
flutter run -d chrome

echo.
echo Application session ended.
pause
