@echo off
REM ============================================
REM Script para subir o projeto pro GitHub
REM Rode este arquivo APÓS criar o repo no site
REM ============================================

echo.
echo 🌾 Stardew-Like - GitHub Setup
echo ===============================
echo.

REM Verifica se está na pasta certa
if not exist "project.godot" (
    echo ❌ ERRO: Rode este script na pasta do projeto (onde está project.godot)
    pause
    exit /b 1
)

echo ✅ Pasta do projeto OK
echo.

REM Pede a URL do repositório
set /p REPO_URL="📋 Cole a URL do seu repo GitHub (ex: https://github.com/seuuser/seurepo.git): "

if "%REPO_URL%"=="" (
    echo ❌ URL vazia. Crie o repo no GitHub primeiro!
    echo.
    echo Passos:
    echo 1. Va em https://github.com/new
    echo 2. Nome: stardew-like (ou o que quiser)
    echo 3. Public ou Private (sua escolha)
    echo 4. NAO marque "Add README", ".gitignore" ou "license" (ja temos)
    echo 5. Create repository
    echo 6. Copie a URL e cole aqui
    pause
    exit /b 1
)

echo.
echo 🔧 Inicializando Git...
git init

echo 📝 Adicionando arquivos...
git add .

echo 💾 Fazendo commit inicial...
git commit -m "🌾 Initial commit: Stardew-Like farming simulator

- Farming system (crops, trees, greenhouse, sprinklers)
- Buildings & animals (15+ buildings, 8 animal types)
- NPCs & social (28 NPCs, 10 heart levels, dating/marriage)
- Mines (120 floors, 3 biomes, combat)
- Fishing minigame with visual bar
- Festivals, Community Center, Museum
- TV channels, mail, secret notes
- Character customization, collections
- HUD with quest tracker, notifications
- Pause/Settings menus, audio/particles
- Save/load (4 slots + autosave)
- 47 JSON data files from Stardew Valley
- Logger with auto-crash save

Personal project - not for publication."

echo 🌐 Conectando ao GitHub...
git branch -M main
git remote add origin "%REPO_URL%"

echo ⬆️ Enviando para GitHub...
git push -u origin main

echo.
echo ===============================
if %errorlevel%==0 (
    echo 🎉 SUCESSO! Repo enviado para GitHub
    echo.
    echo Acesse: %REPO_URL%
) else (
    echo ❌ ERRO no push. Verifique:
    echo - URL correta?
    echo - Repo criado vazio no GitHub?
    echo - Tem permissão de write?
)
echo ===============================
pause