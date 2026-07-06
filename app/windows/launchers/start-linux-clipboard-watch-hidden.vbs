Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
scriptPath = fso.BuildPath(scriptDir, "start-clipboard-watch-hidden.vbs")
sh.Run "wscript.exe //B """ & scriptPath & """", 0, False
