@echo off
chcp 65001 >nul
title Stardew-Like Launcher (Meu PC)

echo.
echo ========================================
echo   STARDEW-LIKE - Godot 4.7.2 (PC do Administrador)
echo ========================================
echo.

SET GODOT_EXE=

REM ========================================
REM CAMINHOS DO SEU PC (EDITE SE MUDAR)
REM ========================================

REM 1. Godot no PATH do Windows (mais rápido)
where godot >nul 2>&1
if %errorlevel% equ 0 (
    SET GODOT_EXE=godot
    echo [OK] Usando Godot do PATH
    goto :launch
)

REM 2. Instalação padrão do Godot 4.7.2 (Program Files)
if exist "%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe" (
    SET GODOT_EXE="%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe"
    echo [OK] Encontrado em Program Files
    goto :launch
)

REM 3. Godot 4.x qualquer versão no Program Files
for /d %%D in ("%ProgramFiles%\Godot\*") do (
    for %%F in ("%%D\Godot_v4*.exe") do (
        SET GODOT_EXE="%%F"
        echo [OK] Encontrado: %%F
        goto :launch
    )
)

REM 4. Program Files (x86)
for /d %%D in ("%ProgramFiles(x86)%\Godot\*") do (
    for %%F in ("%%D\Godot_v4*.exe") do (
        SET GODOT_EXE="%%F"
        echo [OK] Encontrado (x86): %%F
        goto :launch
    )
)

REM 5. LocalAppData (instalação por usuário)
if exist "%LocalAppData%\Godot\Godot_v4.7.2-stable_win64.exe" (
    SET GODOT_EXE="%LocalAppData%\Godot\Godot_v4.7.2-stable_win64.exe"
    echo [OK] Encontrado em LocalAppData
    goto :launch
)

for /d %%D in ("%LocalAppData%\Godot\*") do (
    for %%F in ("%%D\Godot_v4*.exe") do (
        SET GODOT_EXE="%%F"
        echo [OK] Encontrado em LocalAppData: %%F
        goto :launch
    )
)

REM 6. Pasta do usuário (Downloads, Documents, etc.)
if exist "%UserProfile%\Downloads\Godot_v4.7.2-stable_win64.exe" (
    SET GODOT_EXE="%UserProfile%\Downloads\Godot_v4.7.2-stable_win64.exe"
    echo [OK] Encontrado em Downloads
    goto :launch
)

if exist "%UserProfile%\Godot\Godot_v4.7.2-stable_win64.exe" (
    SET GODOT_EXE="%UserProfile%\Godot\Godot_v4.7.2-stable_win64.exe"
    echo [OK] Encontrado em UserProfile\Godot
    goto :launch
)

REM 7. Pastas comuns na raiz C: e D:
if exist "C:\Godot\Godot_v4.7.2-stable_win64.exe" (
    SET GODOT_EXE="C:\Godot\Godot_v4.7.2-stable_win64.exe"
    echo [OK] Encontrado em C:\Godot
    goto :launch
)

if exist "D:\Godot\Godot_v4.7.2-stable_win64.exe" (
    SET GODOT_EXE="D:\Godot\Godot_v4.7.2-stable_win64.exe"
    echo [OK] Encontrado em D:\Godot
    goto :launch
)

REM 8. Busca ampla em C:\Godot\* e D:\Godot\*
for /d %%D in ("C:\Godot\*") do (
    for %%F in ("%%D\Godot_v4*.exe") do (
        SET GODOT_EXE="%%F"
        echo [OK] Encontrado em C:\Godot: %%F
        goto :launch
    )
)

for /d %%D in ("D:\Godot\*") do (
    for %%F in ("%%D\Godot_v4*.exe") do (
        SET GODOT_EXE="%%F"
        echo [OK] Encontrado em D:\Godot: %%F
        goto :launch
    )
)

REM ========================================
REM NÃO ENCONTROU - INSTRUÇÕES
REM ========================================
echo [ERRO] Godot 4.x não encontrado no seu PC!
echo.
echo Instale o Godot 4.7.2 em: https://godotengine.org/download
echo.
echo Ou edite este arquivo e adicione o caminho exato:
echo   SET GODOT_EXE="C:\SEU\CAMINHO\Godot_v4.7.2-stable_win64.exe"
echo.
pause
exit /b 1

:launch
echo.
echo Iniciando Stardew-Like...
echo Projeto: %~dp0
echo.

%GODOT_EXE% --path "%~dp0" --main-pack "%~dp0project.godot"

echo.
echo Jogo finalizado.
pause