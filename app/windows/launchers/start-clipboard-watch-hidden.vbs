Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
scriptPath = fso.BuildPath(scriptDir, "clipboard-watch.ps1")
dist = shell.ExpandEnvironmentStrings("%WSL_WECHAT_DISTRO%")
If dist = "%WSL_WECHAT_DISTRO%" Or dist = "" Then dist = "Ubuntu-22.04"
shell.Run "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File """ & scriptPath & """ -Distro """ & dist & """", 0, False

