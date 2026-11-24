<#
.SYNOPSIS
    Launcher for Stardew-Like Godot project
.DESCRIPTION
    Finds Godot 4.x installation and launches the Stardew-Like project
    Supports command line arguments for customization
#>

param(
    [string]$GodotPath = "",
    [switch]$Debug,
    [switch]$Verbose,
    [string]$Resolution = "",
    [switch]$Fullscreen,
    [string]$ExtraArgs = ""
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   STARDEW-LIKE LAUNCHER (PowerShell)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Find Godot executable
function Find-Godot {
    # 1. Check if path provided
    if ($GodotPath -and (Test-Path $GodotPath)) {
        return $GodotPath
    }

    # 2. Check PATH
    $pathGodot = Get-Command godot -ErrorAction SilentlyContinue
    if ($pathGodot) {
        return $pathGodot.Source
    }

    # 3. Common installation paths
    $commonPaths = @(
        "${env:ProgramFiles}\Godot\Godot_v4.7.2-stable_win64.exe",
        "${env:ProgramFiles(x86)}\Godot\Godot_v4.7.2-stable_win64.exe",
        "${env:LocalAppData}\Godot\Godot_v4.7.2-stable_win64.exe",
        "${env:USERPROFILE}\Godot\Godot_v4.7.2-stable_win64.exe",
        "${env:USERPROFILE}\Downloads\Godot_v4.7.2-stable_win64.exe",
        "C:\Godot\Godot_v4.7.2-stable_win64.exe",
        "D:\Godot\Godot_v4.7.2-stable_win64.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    # 4. Search Program Files for any Godot 4.x
    $godotDirs = Get-ChildItem "${env:ProgramFiles}\Godot", "${env:ProgramFiles(x86)}\Godot" -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }
    foreach ($dir in $godotDirs) {
        $exe = Get-ChildItem $dir.FullName -Filter "Godot_v4*.exe" | Select-Object -First 1
        if ($exe) {
            return $exe.FullName
        }
    }

    return $null
}

# Find project path (script directory)
$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectFile = Join-Path $projectPath "project.godot"

if (-not (Test-Path $projectFile)) {
    Write-Error "project.godot não encontrado em: $projectPath"
    exit 1
}

# Find Godot
Write-Host "Procurando Godot..." -ForegroundColor Yellow
$godotExe = Find-Godot

if (-not $godotExe) {
    Write-Error @"
Godot 4.x não encontrado!

Opções:
1. Instale Godot 4.7.2: https://godotengine.org/download
2. Adicione ao PATH do Windows
3. Passe o caminho via parâmetro: -GodotPath "C:\caminho\Godot.exe"
"@
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "[OK] Godot encontrado: $godotExe" -ForegroundColor Green

# Build arguments
$args = @(
    "--path", $projectPath
)

if ($Debug) { $args += "--verbose" }
if ($Verbose) { $args += "--verbose" }
if ($Resolution) { $args += "--resolution", $Resolution }
if ($Fullscreen) { $args += "--fullscreen" }
if ($ExtraArgs) { $args += $ExtraArgs.Split(" ") }

Write-Host "`nIniciando jogo..." -ForegroundColor Green
Write-Host "Projeto: $projectPath" -ForegroundColor Gray
Write-Host "Args: $($args -join ' ')`n" -ForegroundColor Gray

# Launch
try {
    & $godotExe @args
} catch {
    Write-Error "Erro ao iniciar: $_"
    exit 1
}

Write-Host "`nJogo finalizado." -ForegroundColor Cyan