Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
script = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "clipboard-widget.ps1")
dist = shell.ExpandEnvironmentStrings("%WSL_WECHAT_DISTRO%")
If dist = "%WSL_WECHAT_DISTRO%" Then dist = ""
If dist = "" Then
  distFile = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "distro.txt")
  If fso.FileExists(distFile) Then
    Set stream = fso.OpenTextFile(distFile, 1)
    If Not stream.AtEndOfStream Then dist = Trim(stream.ReadLine)
    stream.Close
  End If
End If
If dist = "" Then dist = "Ubuntu-22.04"
shell.Run "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & script & """ -Distro """ & dist & """", 0, False
