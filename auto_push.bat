@echo off
cd /d "C:\Users\Administrador\Documents\test\stardew_godot"

git add -A

set /p msg="Mensagem do commit: "
if "%msg%"=="" set msg="Update: %date% %time%"

git commit -m "%msg%"
git push

pause