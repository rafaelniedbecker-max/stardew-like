' Stardew-Like - Criador de Atalho para o PC do Administrador
' Execute este arquivo para criar atalho na área de trabalho

Option Explicit

Dim shell, shortcut, desktopPath, targetPath, workDir, iconPath
Dim godotPath, projectPath, arguments

' ========================================
' CONFIGURAÇÃO PARA SEU PC
' ========================================

' Deixe vazio para auto-detectar, ou coloque caminho exato:
' godotPath = "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe"
godotPath = ""

' Seu projeto (já configurado para seu PC)
projectPath = "C:\Users\Administrador\Documents\test\stardew_godot"
arguments = "--path """ & projectPath & """"

' ========================================
' CRIAÇÃO DO ATALHO
' ========================================

Set shell = CreateObject("WScript.Shell")
desktopPath = shell.SpecialFolders("Desktop")
targetPath = desktopPath & "\Stardew-Like.lnk"

' Auto-detecta Godot se não especificado
If godotPath = "" Then
    godotPath = FindGodot()
    If godotPath = "" Then
        MsgBox "Godot 4.x não encontrado no seu PC!" & vbCrLf & _
               "Instale em: https://godotengine.org/download" & vbCrLf & _
               "Ou edite este arquivo e defina 'godotPath' manualmente.", vbCritical, "Erro"
        WScript.Quit 1
    End If
End If

' Verifica projeto
Dim fso
Set fso = CreateObject("Scripting.FileSystemObject")
If Not fso.FileExists(projectPath & "\project.godot") Then
    MsgBox "Projeto não encontrado em: " & projectPath, vbCritical, "Erro"
    WScript.Quit 1
End If

' Cria atalho
Set shortcut = shell.CreateShortcut(targetPath)
shortcut.TargetPath = godotPath
shortcut.Arguments = arguments
shortcut.WorkingDirectory = projectPath
shortcut.Description = "Stardew-Like - Godot 4.7.2 (Meu PC)"
shortcut.IconLocation = godotPath & ",0"
shortcut.Save

MsgBox "Atalho criado na Área de Trabalho!" & vbCrLf & _
       "Local: " & targetPath & vbCrLf & _
       "Godot: " & godotPath, vbInformation, "Sucesso"

' ========================================
' AUTO-DETECÇÃO DO GODOT NO SEU PC
' ========================================
Function FindGodot()
    Dim paths, path, fso, dir, file, wshExec, output
    Set fso = CreateObject("Scripting.FileSystemObject")

    ' 1. PATH do sistema
    On Error Resume Next
    Set wshExec = shell.Exec("where godot")
    output = wshExec.StdOut.ReadAll
    If Len(output) > 0 Then
        FindGodot = Trim(output)
        Exit Function
    End If
    On Error GoTo 0

    ' 2. Locais do SEU PC (ordem de prioridade)
    paths = Array( _
        "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe", _
        "C:\Program Files (x86)\Godot\Godot_v4.7.2-stable_win64.exe", _
        fso.GetSpecialFolder(1) & "\Godot\Godot_v4.7.2-stable_win64.exe", _ ' LocalAppData
        fso.GetSpecialFolder(0) & "\Godot\Godot_v4.7.2-stable_win64.exe", _ ' AppData
        fso.GetSpecialFolder(5) & "\Godot_v4.7.2-stable_win64.exe",  _ ' Desktop
        "C:\Godot\Godot_v4.7.2-stable_win64.exe", _
        "D:\Godot\Godot_v4.7.2-stable_win64.exe"
    )

    For Each path In paths
        If fso.FileExists(path) Then
            FindGodot = path
            Exit Function
        End If
    Next

    ' 3. Procura em Program Files\Godot\*
    Dim progFiles, progFiles86, folder, file
    progFiles = fso.GetSpecialFolder(1) & "\Godot"
    progFiles86 = fso.GetSpecialFolder(2) & "\Godot"

    For Each dir In Array(progFiles, progFiles86)
        If fso.FolderExists(dir) Then
            Set folder = fso.GetFolder(dir)
            For Each file In folder.Files
                If InStr(LCase(file.Name), "godot_v4") > 0 And Right(LCase(file.Name), 4) = ".exe" Then
                    FindGodot = file.Path
                    Exit Function
                End If
            Next
        End If
    Next

    FindGodot = ""
End Function