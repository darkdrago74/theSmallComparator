@echo off
setlocal EnableDelayedExpansion

echo ==========================================
echo   theSmallComparator Smart Start (Windows)
echo ==========================================

:: Assuming the server runs on port 5001, we ensure it's free
call :KillPort 5001

echo.
echo Starting theSmallComparator...
echo   - Local URL: http://localhost:5001
echo.

if not exist venv\Scripts\python.exe (
    echo [ERROR] Virtual environment not found. Please run install.bat first.
    pause
    exit /b 1
)

call venv\Scripts\python.exe main.py
pause
exit /b

:KillPort
set "port=%~1"
for /f "tokens=5" %%a in ('netstat -aon ^| find ":%port%" ^| find "LISTENING"') do (
    echo [AUTO-KILL] Port %port% is in use by PID %%a. Killing...
    taskkill /F /PID %%a >nul 2>&1
)
exit /b 0
