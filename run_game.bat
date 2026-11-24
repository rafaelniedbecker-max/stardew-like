@echo off
chcp 65001 >nul
title Stardew-Like (Meu PC)

echo Iniciando Stardew-Like...

REM Tenta Godot do PATH
where godot >nul 2>&1
if %errorlevel% equ 0 (
    godot --path "%~dp0" --main-pack "%~dp0project.godot"
    goto :end
)

REM Fallback: Program Files padrão
if exist "%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe" (
    "%ProgramFiles%\Godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0" --main-pack "%~dp0project.godot"
    goto :end
)

echo Godot nao encontrado! Instale em https://godotengine.org/download
pause

:end