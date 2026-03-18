@echo off
setlocal EnableDelayedExpansion

echo ==========================================
echo theSmallComparator Windows Installer
echo ==========================================
echo.
echo NOTE: Ensure you are running this as Administrator if you encounter permission errors.
echo.

:: Check for Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Python is not installed or not in PATH.
    echo We are going to download and install Python 3 automatically.
    echo Please ensure you are running this script as Administrator.
    pause
    echo Downloading Python installer ^(3.11.9^)...
    curl -# -o python_installer.exe https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to download Python. Please install manually from https://www.python.org/
        pause
        exit /b 1
    )
    echo Installing Python...
    start /wait python_installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    del python_installer.exe
    echo Python installed successfully.
    echo [IMPORTANT] You must close this window and run install.bat again to load the new PATH.
    pause
    exit /b 0
) else (
    for /f "tokens=*" %%i in ('python --version') do set py_ver=%%i
    echo [CHECK] Found !py_ver!.
)

echo.
echo [1/3] Creating virtual environment...
if not exist venv (
    python -m venv venv
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
    echo Virtual environment created successfully.
) else (
    echo [CHECK] Virtual environment already exists.
)

echo.
echo [2/3] Upgrading pip, setuptools, and wheel...
call venv\Scripts\python.exe -m pip install --upgrade pip setuptools wheel
if %errorlevel% neq 0 (
    echo [ERROR] Failed to upgrade pip.
    pause
    exit /b 1
)

echo.
echo [3/3] Installing dependencies...
echo Installing heavy dependencies (numpy, opencv-python-headless, Pillow)...
call venv\Scripts\python.exe -m pip install --no-cache-dir "numpy>=1.24.3" "opencv-python-headless>=4.10.0.84" "Pillow>=10.0.0"

echo.
echo Installing requirements from dependencies\requirements-simple.txt...
if exist dependencies\requirements-simple.txt (
    call venv\Scripts\python.exe -m pip install --no-cache-dir -r dependencies\requirements-simple.txt
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install dependencies.
        pause
        exit /b 1
    )
) else (
    echo [ERROR] dependencies\requirements-simple.txt not found.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Installation Complete!
echo You can now run 'start.bat' to launch theSmallComparator.
echo ==========================================
pause
