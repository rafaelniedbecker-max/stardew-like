<#
.SYNOPSIS
    Launcher Stardew-Like personalizado para o PC do Administrador
.DESCRIPTION
    Detecta Godot nos locais padrão do Windows e lança o projeto
#>

param(
    [switch]$Debug,
    [switch]$Verbose,
    [string]$Resolution = "",
    [switch]$Fullscreen,
    [string]$ExtraArgs = ""
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   STARDEW-LIKE - PC do Administrador" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Caminho do projeto (pasta onde este script está)
$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectFile = Join-Path $projectPath "project.godot"

if (-not (Test-Path $projectFile)) {
    Write-Error "project.godot não encontrado em: $projectPath"
    exit 1
}

# Função para encontrar Godot no SEU PC
function Find-MeuGodot {
    Write-Host "Procurando Godot no seu PC..." -ForegroundColor Yellow

    # 1. PATH do sistema
    $pathGodot = Get-Command godot -ErrorAction SilentlyContinue
    if ($pathGodot) {
        Write-Host "[OK] Godot no PATH: $($pathGodot.Source)" -ForegroundColor Green
        return $pathGodot.Source
    }

    # 2. Program Files (instalação padrão)
    $pf = "${env:ProgramFiles}\Godot\Godot_v4.7.2-stable_win64.exe"
    if (Test-Path $pf) {
        Write-Host "[OK] Encontrado em Program Files" -ForegroundColor Green
        return $pf
    }

    # 3. Qualquer Godot 4.x no Program Files
    $godotDirs = Get-ChildItem "${env:ProgramFiles}\Godot", "${env:ProgramFiles(x86)}\Godot" -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }
    foreach ($dir in $godotDirs) {
        $exe = Get-ChildItem $dir.FullName -Filter "Godot_v4*.exe" | Select-Object -First 1
        if ($exe) {
            Write-Host "[OK] Encontrado: $($exe.FullName)" -ForegroundColor Green
            return $exe.FullName
        }
    }

    # 4. LocalAppData
    $localApp = "${env:LocalAppData}\Godot\Godot_v4.7.2-stable_win64.exe"
    if (Test-Path $localApp) {
        Write-Host "[OK] Encontrado em LocalAppData" -ForegroundColor Green
        return $localApp
    }

    # 5. Pastas do usuário
    $userPaths = @(
        "${env:USERPROFILE}\Downloads\Godot_v4.7.2-stable_win64.exe",
        "${env:USERPROFILE}\Godot\Godot_v4.7.2-stable_win64.exe",
        "C:\Godot\Godot_v4.7.2-stable_win64.exe",
        "D:\Godot\Godot_v4.7.2-stable_win64.exe"
    )

    foreach ($p in $userPaths) {
        if (Test-Path $p) {
            Write-Host "[OK] Encontrado em: $p" -ForegroundColor Green
            return $p
        }
    }

    # Busca ampla em C:\Godot\* e D:\Godot\*
    foreach ($drive in "C:\Godot", "D:\Godot") {
        if (Test-Path $drive) {
            $exe = Get-ChildItem $drive -Filter "Godot_v4*.exe" -Recurse | Select-Object -First 1
            if ($exe) {
                Write-Host "[OK] Encontrado em $drive: $($exe.FullName)" -ForegroundColor Green
                return $exe.FullName
            }
        }
    }

    return $null
}

# Encontra Godot
Write-Host "`nProcurando Godot no seu PC..." -ForegroundColor Yellow
$godotExe = Find-MeuGodot

if (-not $godotExe) {
    Write-Error @"
Godot 4.x não encontrado no seu PC!

Opções:
1. Instale Godot 4.7.2: https://godotengine.org/download
2. Instale no local padrão: C:\Program Files\Godot\
3. Ou adicione ao PATH do Windows
"@
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host "`n[OK] Godot: $godotExe" -ForegroundColor Green

# Argumentos
$args = @("--path", $projectPath)
if ($Debug) { $args += "--verbose" }
if ($Verbose) { $args += "--verbose" }
if ($Resolution) { $args += "--resolution", $Resolution }
if ($Fullscreen) { $args += "--fullscreen" }
if ($ExtraArgs) { $args += $ExtraArgs.Split(" ") }

Write-Host "`nIniciando Stardew-Like no seu PC..." -ForegroundColor Green
Write-Host "Projeto: $projectPath`n" -ForegroundColor Gray

try {
    & $godotExe @args
} catch {
    Write-Error "Erro: $_"
    exit 1
}

Write-Host "`nJogo finalizado." -ForegroundColor Cyan