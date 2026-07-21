Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
scriptPath = fso.BuildPath(scriptDir, "clipboard-watch.ps1")
dist = shell.ExpandEnvironmentStrings("%WSL_WECHAT_DISTRO%")
If dist = "%WSL_WECHAT_DISTRO%" Then dist = ""
If dist = "" Then
  distFile = fso.BuildPath(scriptDir, "distro.txt")
  If fso.FileExists(distFile) Then
    Set stream = fso.OpenTextFile(distFile, 1)
    If Not stream.AtEndOfStream Then dist = Trim(stream.ReadLine)
    stream.Close
  End If
End If
If dist = "" Then dist = "Ubuntu-22.04"
shell.Run "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File """ & scriptPath & """ -Distro """ & dist & """", 0, False

