# Commands

Use these for the user's local `Ubuntu-22.04` setup.

## Daily Commands

```powershell
# Start
wsl -d Ubuntu-22.04 -- wechat-desktop

# Status
wsl -d Ubuntu-22.04 -- wechat-desktop-status

# Public repo health check
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -Distro Ubuntu-22.04

# Stop
wsl -d Ubuntu-22.04 -- wechat-desktop-stop

# Force stop if WeChat says it is already open or locked
wsl -d Ubuntu-22.04 -- wechat-desktop-stop --force

# Test Windows notification helper. Default behavior is taskbar flash only;
# popup appears only when NoticePopupEnabled=true in settings.json.
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge --test

# Restart notification bridge
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge-restart

# Notification bridge status; should also show notification_daemon=running
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge --status

# Linux focus bridge status; active_name should be wsl-focus-sink when Windows foreground is not WeChat Desktop
wsl -d Ubuntu-22.04 -- wsl-app-focus-bridge --status

# Start real-time foreground/focus watcher
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-focus-watch-hidden.vbs"

# Stop real-time foreground/focus watcher
& "$env:LOCALAPPDATA\WslPrivate\launchers\stop-focus-watch.cmd"

# Manual clipboard sync: text, image, or copied files
wsl -d Ubuntu-22.04 -- winclip2wechat

# Open manual clipboard sync widget
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-widget-hidden.vbs"

# Sync clipboard and paste into active WeChat input
wsl -d Ubuntu-22.04 -- winclip2wechat --paste

# Copy Linux WeChat/X11 text clipboard to Windows clipboard
wsl -d Ubuntu-22.04 -- wechatclip2win

# Start unified bidirectional clipboard watcher
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-watch-hidden.vbs"

# Stop unified bidirectional clipboard watcher
& "$env:LOCALAPPDATA\WslPrivate\launchers\stop-clipboard-watch.cmd"

# Unified clipboard watcher log
Get-Content "$env:LOCALAPPDATA\WslPrivate\launchers\clipboard-watch.log" -Tail 80

# Check Windows file links for direct file sending from Linux WeChat
wsl -d Ubuntu-22.04 -- bash -lc "ls -ld ~/Windows-* /mnt/c 2>/dev/null"
```

## User-Facing Docs

```powershell
notepad .\README.md
notepad .\docs\ARCHITECTURE.md
```

Keep daily command docs short. Put longer explanations in `docs/`.

## Diagnostic Commands

```powershell
wsl -d Ubuntu-22.04 -- bash -lc "command -v wechat-desktop wechat-desktop-status wechat-desktop-stop wechat-restore winclip2wechat wechatclip2win wsl-app-notify-bridge wsl-app-notify-bridge-restart wsl-app-focus-bridge wsl-focus-sink"
wsl -d Ubuntu-22.04 -- bash -lc "tail -n 80 ~/.cache/wechat-desktop/notice-bridge.log"
wsl -d Ubuntu-22.04 -- bash -lc "tail -n 80 ~/.cache/wechat-desktop/notification-daemon.log"
wsl -d Ubuntu-22.04 -- bash -lc "tail -n 80 ~/.cache/wechat-desktop/focus-bridge.log"
Get-Content "$env:LOCALAPPDATA\WslPrivate\launchers\focus-watch.log" -Tail 60
wsl -d Ubuntu-22.04 -- bash -lc "tail -n 80 ~/.cache/wechat-desktop/wechatclip2win.log"
Get-Content "$env:LOCALAPPDATA\WslPrivate\launchers\notice.log" -Tail 40
Get-StartApps | Where-Object { $_.Name -match '(?i)wechat|weixin|微信' -or $_.AppID -match '(?i)wechat|weixin|微信' }
```
