@echo off
REM Batch script to run PBR texture conversion on Windows
REM Requires: Python 3.8+ with Pillow (pip install pillow)

cd /d "%~dp0\.."

echo ========================================
echo  PBR Texture Converter for Godot 4
echo ========================================
echo.

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found in PATH
    echo Install from https://python.org
    pause
    exit /b 1
)

REM Check Pillow
python -c "import PIL" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Installing Pillow...
    pip install pillow
    if errorlevel 1 (
        echo [ERROR] Failed to install Pillow
        pause
        exit /b 1
    )
)

echo [RUN] Converting textures...
python scripts/convert_pbr_textures.py

echo.
echo [DONE] Check assets/textures/pbr_ready/ and assets/materials/
echo.
pause