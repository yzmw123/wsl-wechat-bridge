Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
script = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "focus-watch.ps1")
dist = sh.ExpandEnvironmentStrings("%WSL_WECHAT_DISTRO%")
If dist = "%WSL_WECHAT_DISTRO%" Or dist = "" Then dist = "Ubuntu-22.04"
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & script & """ -Distro """ & dist & """"
sh.Run cmd, 0, False
