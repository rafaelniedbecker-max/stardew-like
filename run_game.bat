@echo off
chcp 65001 >nul
title Stardew-Like Launcher

echo.
echo ========================================
echo   STARDEW-LIKE - Godot 4.7.2
echo ========================================
echo.

REM Verifica se Godot está no PATH
where godot >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] Godot não encontrado no PATH!
    echo.
    echo Opções:
    echo  1. Adicione Godot ao PATH do Windows
    echo 2. Edite este arquivo e defina GODOT_PATH abaixo
    echo 3. Baixe em: https://godotengine.org/download
    echo.
    pause
    exit /b 1
)

echo [OK] Godot encontrado: %GODOT_PATH%
echo.
echo Iniciando jogo...
echo.

REM Executa o projeto
godot --path "%~dp0" --main-pack "%~dp0project.godot"

echo.
echo Jogo finalizado.
pause