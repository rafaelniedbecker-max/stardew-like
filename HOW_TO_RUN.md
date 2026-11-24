# Como rodar o Stardew-Like

## Opção 1: Script Batch Simples (Recomendado)
```bash
# Duplo clique em:
run_game.bat
```
- Verifica se Godot está no PATH
- Executa o projeto automaticamente

## Opção 2: Script Batch Avançado
```bash
# Duplo clique em:
run_game_advanced.bat
```
- Procura Godot automaticamente em locais comuns
- Funciona mesmo se Godot não estiver no PATH
- Suporta múltiplas versões 4.x

## Opção 3: PowerShell (Mais flexível)
```powershell
# Clique com botão direito → "Executar com PowerShell"
.\Run_Stardew_Like.ps1

# Ou com parâmetros:
.\Run_Stardew_Like.ps1 -Debug -Verbose -Resolution "1920x1080" -Fullscreen
```

## Opção 4: Criar Atalho na Área de Trabalho
```bash
# Duplo clique em:
create_shortcut.vbs
```
- Cria atalho `Stardew-Like.lnk` na área de trabalho
- Detecta Godot automaticamente
- Ícone do Godot no atalho

## Opção 5: Linha de Comando Direta
```cmd
# Se Godot estiver no PATH:
godot --path "C:\Users\Administrador\Documents\test\stardew_godot"

# Ou caminho completo:
"C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe" --path "C:\Users\Administrador\Documents\test\stardew_godot"
```

## Opção 6: Godot Editor
1. Abra **Godot 4.7.2**
2. Clique em **Importar** → selecione `project.godot`
3. Clique no botão **Play** (F5) ou **Run Project**

---

## Requisitos
- **Godot 4.7.2** (ou 4.x compatível)
- Windows 10/11 (testado)
- 4GB+ RAM recomendado

## Download Godot
- Oficial: https://godotengine.org/download
- Escolha **Standard** (não .NET) para Windows 64-bit
- Versão usada no desenvolvimento: **4.7.2-stable**

---

## Solução de Problemas

### "Godot não encontrado"
1. Instale Godot 4.7.2+
2. Adicione ao PATH: `C:\Program Files\Godot` (ou onde instalou)
3. Ou edite `run_game_advanced.bat` e defina `SET GODOT_EXE="C:\caminho\Godot.exe"`

### "Project.godot não encontrado"
- Execute os scripts a partir da pasta do projeto: `C:\Users\Administrador\Documents\test\stardew_godot`

### Erro de encoding (caracteres estranhos)
- Use `run_game_advanced.bat` que tem `chcp 65001` (UTF-8)
- Ou rode no terminal moderno (Windows Terminal, PowerShell 7+)

### Jogo não abre / tela preta
- Verifique se é Godot 4.x (não 3.x)
- Tente `--rendering-driver vulkan` ou `--rendering-driver opengl3`
- Atualize drivers de vídeo

---

## Estrutura do Projeto
```
stardew_godot/
├── run_game.bat              # Launcher simples
├── run_game_advanced.bat     # Launcher com auto-detect
├── Run_Stardew_Like.ps1      # Launcher PowerShell
├── create_shortcut.vbs       # Criador de atalho
├── project.godot             # Config principal
├── scenes/                   # Cenas (.tscn)
├── scripts/                  # Scripts GDScript (90 arquivos)
├── resources/                # Dados JSON (167 arquivos)
└── HOW_TO_RUN.md            # Este arquivo
```

---

## Controles Padrão
| Ação | Tecla |
|------|-------|
| Mover | WASD / Setas |
| Interagir | E / Espaço |
| Ferramenta | Botão esquerdo do mouse |
| Ferramenta alternativa | Botão direito do mouse |
| Inventário | Tab / I |
| Pausar | Escape |
| Hotbar 1-8 | 1-8 |

---

**Divirta-se!** 🌱🎮