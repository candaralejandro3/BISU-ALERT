@echo off
title BISU-Alert WAMP Server Launcher
cd /d "%~dp0\.."

echo =======================================================
echo          BISU-Alert WAMP Server Launcher
echo =======================================================
echo.

:: 1. Check if WAMP MySQL is running on port 3306
netstat -ano | findstr ":3306 " >nul
if %ERRORLEVEL% equ 0 (
    echo [OK] WAMP MySQL is active on port 3306.
) else (
    echo [INFO] Starting WAMP MySQL (mysql8.4.7)...
    start "" /b "C:\wamp64\bin\mysql\mysql8.4.7\bin\mysqld.exe" --defaults-file="C:\wamp64\bin\mysql\mysql8.4.7\my.ini" --console
    timeout /t 3 /nobreak >nul
)

:: 2. Check if WAMP Apache is running on port 80
netstat -ano | findstr ":80 " >nul
if %ERRORLEVEL% equ 0 (
    echo [OK] WAMP Apache is active on port 80.
) else (
    echo [INFO] Starting WAMP Apache...
    start "" /b "C:\wamp64\bin\apache\apache2.4.65\bin\httpd.exe"
    timeout /t 2 /nobreak >nul
)

:: 3. Find local IP for physical phone testing
for /f "tokens=4" %%a in ('route print^|find " 0.0.0.0"') do (
    set LOCAL_IP=%%a
    goto :ip_found
)
:ip_found
echo.
echo =======================================================
echo Live WAMP URLs:
echo   - Admin Dashboard:         http://localhost/bisu-alert/admin/index.html
echo   - Backend API:             http://localhost/bisu-alert/backend/api
echo   - DB Connection Test:      http://localhost/bisu-alert/backend/api/test_db.php
if defined LOCAL_IP (
    echo.
    echo Mobile / Network Access (Wi-Fi):
    echo   - Physical Device API:     http://%LOCAL_IP%/bisu-alert/backend/api
    echo   - Admin Panel (Wi-Fi):     http://%LOCAL_IP%/bisu-alert/admin/index.html
)
echo   - Android Emulator API:    http://10.0.2.2/bisu-alert/backend/api
echo =======================================================
echo.

echo Opening Admin Dashboard in default browser...
start "" "http://localhost/bisu-alert/admin/login.html"

echo.
echo Server is running. Press any key to exit this launcher window...
pause >nul

