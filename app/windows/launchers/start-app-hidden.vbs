Set shell = CreateObject("WScript.Shell")
dist = shell.ExpandEnvironmentStrings("%WSL_WECHAT_DISTRO%")
If dist = "%WSL_WECHAT_DISTRO%" Or dist = "" Then dist = "Ubuntu-22.04"
shell.Run "wsl -d " & Chr(34) & dist & Chr(34) & " -- wechat-desktop", 0, False

