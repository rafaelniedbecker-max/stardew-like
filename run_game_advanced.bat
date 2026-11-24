@echo off
chcp 65001 >nul
title Stardew-Like Launcher (Advanced)

echo.
echo ========================================
echo   STARDEW-LIKE - Godot 4.7.2
echo ========================================
echo.

SET GODOT_EXE=

REM 1. Tenta Godot no PATH
where godot >nul 2>&1
if %errorlevel% equ 0 (
    SET GODOT_EXE=godot
    goto :launch
)

REM 2. Locais comuns de instalação
set "COMMON_PATHS="
set "COMMON_PATHS=%COMMON_PATHS% %ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe"
set "COMMON_PATHS=%COMMON_PATHS% %ProgramFiles(x86)%\Godot\Godot_v4.7.2-stable_win64.exe"
set "COMMON_PATHS=%COMMON_PATHS% %LocalAppData%\Godot\Godot_v4.7.2-stable_win64.exe"
set "COMMON_PATHS=%COMMON_PATHS% %UserProfile%\Godot\Godot_v4.7.2-stable_win64.exe"
set "COMMON_PATHS=%COMMON_PATHS% %UserProfile%\Downloads\Godot_v4.7.2-stable_win64.exe"
set "COMMON_PATHS=%COMMON_PATHS% C:\Godot\Godot_v4.7.2-stable_win64.exe"
set "COMMON_PATHS=%COMMON_PATHS% D:\Godot\Godot_v4.7.2-stable_win64.exe"

for %%P in (%COMMON_PATHS%) do (
    if exist "%%P" (
        SET GODOT_EXE="%%P"
        goto :launch
    )
)

REM 3. Procura qualquer Godot 4.x na pasta Program Files
for /d %%D in ("%ProgramFiles%\Godot\*") do (
    for %%F in ("%%D\Godot_v4*.exe") do (
        SET GODOT_EXE="%%F"
        goto :launch
    )
)

for /d %%D in ("%ProgramFiles(x86)%\Godot\*") do (
    for %%F in ("%%D\Godot_v4*.exe") do (
        SET GODOT_EXE="%%F"
        goto :launch
    )
)

REM 4. Não encontrou
echo [ERRO] Godot 4.x não encontrado automaticamente!
echo.
echo Opções:
echo  1. Instale Godot 4.7.2 em: https://godotengine.org/download
echo  2. Adicione Godot ao PATH do Windows (Variáveis de Ambiente)
echo  3. Edite este arquivo e defina manualmente:
echo     SET GODOT_EXE="C:\caminho\para\Godot_v4.7.2-stable_win64.exe"
echo.
pause
exit /b 1

:launch
echo [OK] Godot encontrado: %GODOT_EXE%
echo.
echo Iniciando Stardew-Like...
echo.

%GODOT_EXE% --path "%~dp0" --main-pack "%~dp0project.godot"

echo.
echo Jogo finalizado.
pause