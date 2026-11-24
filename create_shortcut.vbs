' Stardew-Like Desktop Shortcut Creator
' Execute este arquivo para criar atalho na área de trabalho

Option Explicit

Dim shell, shortcut, desktopPath, targetPath, workDir, iconPath
Dim godotPath, projectPath, arguments

' Configuração - EDITE SE NECESSÁRIO
godotPath = ""  ' Deixe vazio para auto-detectar, ou coloque caminho completo: "C:\Godot\Godot_v4.7.2-stable_win64.exe"
projectPath = "C:\Users\Administrador\Documents\test\stardew_godot"
arguments = "--path """ & projectPath & """"

' Caminho da área de trabalho
Set shell = CreateObject("WScript.Shell")
desktopPath = shell.SpecialFolders("Desktop")
targetPath = desktopPath & "\Stardew-Like.lnk"

' Tenta encontrar Godot automaticamente se não especificado
If godotPath = "" Then
    godotPath = FindGodot()
    If godotPath = "" Then
        MsgBox "Godot 4.x não encontrado!" & vbCrLf & _
               "Por favor, edite este arquivo e defina 'godotPath' manualmente.", vbCritical, "Erro"
        WScript.Quit 1
    End If
End If

' Verifica se projeto existe
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
shortcut.Description = "Stardew-Like - Godot 4.7.2"
shortcut.IconLocation = godotPath & ",0"
shortcut.Save

MsgBox "Atalho criado com sucesso!" & vbCrLf & _
       "Local: " & targetPath & vbCrLf & _
       "Godot: " & godotPath, vbInformation, "Sucesso"

Function FindGodot()
    Dim paths, path, fso, dir, file
    Set fso = CreateObject("Scripting.FileSystemObject")

    ' 1. PATH do sistema
    On Error Resume Next
    Dim wshExec, output
    Set wshExec = shell.Exec("where godot")
    output = wshExec.StdOut.ReadAll
    If Len(output) > 0 Then
        FindGodot = Trim(output)
        Exit Function
    End If
    On Error GoTo 0

    ' 2. Locais comuns
    paths = Array( _
        "C:\Godot\Godot_v4.7.2-stable_win64.exe", _
        "D:\Godot\Godot_v4.7.2-stable_win64.exe", _
        "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe", _
        "C:\Program Files (x86)\Godot\Godot_v4.7.2-stable_win64.exe", _
        fso.GetSpecialFolder(1) & "\Godot\Godot_v4.7.2-stable_win64.exe", _ ' LocalAppData
        fso.GetSpecialFolder(0) & "\Godot\Godot_v4.7.2-stable_win64.exe", _ ' AppData
        fso.GetSpecialFolder(5) & "\Godot_v4.7.2-stable_win64.exe"  _ ' Desktop
    )

    For Each path In paths
        If fso.FileExists(path) Then
            FindGodot = path
            Exit Function
        End If
    Next

    ' 3. Procura em Program Files
    Dim progFiles, progFiles86
    progFiles = fso.GetSpecialFolder(1) & "\Godot" ' ProgramFiles
    progFiles86 = fso.GetSpecialFolder(2) & "\Godot" ' ProgramFiles(x86)

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