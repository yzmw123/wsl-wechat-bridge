# Troubleshooting

## Status First

Start with the read-only status script:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\wsl-wechat-helper\scripts\collect-status.ps1 -Distro Ubuntu-22.04
```

The collector redacts legacy titles, notification summaries/bodies, and clipboard paths from old logs. Then use targeted commands from `commands.md`.

## Notification Test Does Not Flash Taskbar

Run:

```powershell
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge --test
powershell -ExecutionPolicy Bypass -File .\skills\wsl-wechat-helper\scripts\collect-status.ps1 -Distro Ubuntu-22.04
```

Expected:

- Bridge log includes `notify reason=manual-test`.
- Bridge log includes `launch=start-process`.
- Windows helper log includes `start title_chars=... body_chars=...`, `flashed=1`, `popup=disabled` when popups are off, and `done`.
- `wsl-app-notify-bridge --status` includes `notification_daemon=running`.

The popup is disabled by default. Enable it from the widget's `消息弹窗` checkbox only when a visible popup is wanted; taskbar flashing should work regardless.

If bridge logs `notify` but the Windows log does not update:

- Check `%LOCALAPPDATA%\WslPrivate\launchers\notice.ps1` exists.
- Check `/usr/local/bin/wsl-app-notify-bridge` uses `WSL_NOTICE_HELPER` and `WSLENV=WSL_NOTICE_HELPER`.
- If logs contain an unexpanded Windows profile placeholder, reinstall the fixed `wsl-app-notify-bridge` and `wsl-app-notification-daemon`; helper path detection must prefer `%LOCALAPPDATA%` and reject unexpanded `%...%` values.
- Avoid plain backgrounded `powershell.exe ... &` from WSL for GUI helpers; it can die with the short WSL command.
- Avoid relying on `powershell.exe -Command 'param(...)'` for the helper path; Windows PowerShell may not bind the path the way Bash callers expect.

If popup is enabled and appears but no taskbar flash:

- Check the Windows window title. The title can include `[WARN:COPY MODE]`.
- `notice.ps1` should match title substrings such as `WeChat Desktop` and `Ubuntu-22.04`, not an exact title only.

Restart the bridge:

```powershell
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge-restart
```

## Manual Test Works But Real Messages Do Not

Check whether the Linux notification daemon is running:

```powershell
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge --status
powershell -ExecutionPolicy Bypass -File .\skills\wsl-wechat-helper\scripts\collect-status.ps1 -Distro Ubuntu-22.04
```

Expected:

- `notification_daemon=running`.
- `notification-daemon.log` has a `started ... bus=...` line.
- `notification-daemon.log` has a `file-watch started ...` line.
- `notification-daemon.log` has `file-notice-mode=log-only`.
- When a real Linux notification arrives, it logs `dbus-notify ...` with lengths and hashes, not summary/body text.
- When the file watcher sees WeChat message/session activity, it logs `file-activity ...` followed by `file-notice-suppressed=log-only`; it should not send a Windows notice by default.

If `notification_daemon=stopped`, restart:

```powershell
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge-restart
```

If the daemon is running but no `dbus-notify` appears during a real message, WeChat did not emit a standard Linux notification for that event. `file-activity ...` only proves storage changed and remains diagnostic because those writes include muted-group, official-account, service-account, cross-device sync, and self-sent-message activity.

The default unread badge watcher should cover normal private chats that display a numbered red badge. Check `wechat-desktop-status` and `~/.cache/wechat-desktop/badge-notify-watch.log`; plain red dots are intentionally ignored. Set `BADGE_WATCH_ENABLED=0` only when the user wants to disable screenshot polling.

## WeChat Still Thinks It Is Foreground

Check the real-time focus watcher:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\WslPrivate\launchers\focus-watch.ps1" -Status
wsl -d Ubuntu-22.04 -- wsl-app-focus-bridge --status
Get-Content "$env:LOCALAPPDATA\WslPrivate\launchers\focus-watch.log" -Tail 60
Get-Content "$env:LOCALAPPDATA\WslPrivate\launchers\focus-watch.state"
```

Expected when Windows foreground is not WeChat Desktop:

- `focus_watch=running ...`
- `active_name=wsl-focus-sink`
- `focus-watch.log` has a recent `windows_foreground=inactive ...` line.
- `focus-watch.state` contains `timestamp` and `state` only; it should not contain `title=`.

Restart only the watcher, not WeChat:

```powershell
& "$env:LOCALAPPDATA\WslPrivate\launchers\stop-focus-watch.cmd"
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-focus-watch-hidden.vbs"
```

To simulate WeChat grabbing Linux focus while Windows foreground is elsewhere, run:

```powershell
wsl -d Ubuntu-22.04 -- wsl-app-focus-bridge --wechat-active
Start-Sleep -Seconds 4
wsl -d Ubuntu-22.04 -- wsl-app-focus-bridge --status
```

The status should return to `active_name=wsl-focus-sink`.

## Clipboard Sync Problems

Windows to Linux manual test:

```powershell
wsl -d Ubuntu-22.04 -- winclip2wechat
wsl -d Ubuntu-22.04 -- winclip2wechat --paste
```

Manual widget:

```powershell
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-widget-hidden.vbs"
```

The widget should preview current Windows clipboard text, image, or files. Its `同步到 WSL` button restores that preview into the Windows clipboard and then calls `winclip2wechat`.

Linux WeChat to Windows manual test:

```powershell
wsl -d Ubuntu-22.04 -- wechatclip2win
Get-Clipboard
```

Unified bidirectional watcher controls:

```powershell
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-watch-hidden.vbs"
& "$env:LOCALAPPDATA\WslPrivate\launchers\stop-clipboard-watch.cmd"
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\WslPrivate\launchers\clipboard-watch.ps1" -Status
Get-Content "$env:LOCALAPPDATA\WslPrivate\launchers\clipboard-watch.log" -Tail 80
```

There should be no separate `wechatclip2win --watch` process:

```powershell
wsl -d Ubuntu-22.04 -- wechatclip2win --status
```

If the log is missing, the watcher may not have been started yet.

Clipboard payload temp files should be under a private runtime/cache directory (`$XDG_RUNTIME_DIR/wsl-wechat-bridge` or `~/.cache/wechat-desktop/runtime/wsl-wechat-bridge`), not `~/Pictures/WindowsClipboard`. `winclip2wechat` should report file counts and image byte sizes by default, not Windows paths.

## WeChat Says It Is Already Open or Locked

Use the installed stop helper:

```powershell
wsl -d Ubuntu-22.04 -- wechat-desktop-stop
```

Normal stop sends `SIGTERM` and returns non-zero if processes survive. Inspect matches without stopping:

```powershell
wsl -d Ubuntu-22.04 -- wechat-desktop-stop --dry-run
```

If still stuck and the user accepts a forceful stop:

```powershell
wsl -d Ubuntu-22.04 -- wechat-desktop-stop --force
```

Avoid broad `pkill -f` patterns from one-line `bash -lc` commands because they can match and kill the current shell.

## Windows Search Still Shows WeChat

Check:

```powershell
Get-StartApps | Where-Object { $_.Name -match '(?i)wechat|weixin|微信' -or $_.AppID -match '(?i)wechat|weixin|微信' }
```

Remove WSLg exported shortcut:

```powershell
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Ubuntu-22.04\wechat (Ubuntu-22.04).lnk" -Force -ErrorAction SilentlyContinue
```

Hide Linux `.desktop` exports:

```powershell
wsl -d Ubuntu-22.04 -- bash -lc "mkdir -p ~/.local/share/applications-codex-hidden; mv ~/.local/share/applications/wechat*.desktop ~/.local/share/applications-codex-hidden/ 2>/dev/null || true; sudo mkdir -p /usr/share/applications-codex-hidden; sudo mv /usr/share/applications/wechat.desktop /usr/share/applications-codex-hidden/ 2>/dev/null || true; update-desktop-database ~/.local/share/applications 2>/dev/null || true; sudo update-desktop-database /usr/share/applications 2>/dev/null || true"
```

Do not hide project documentation or user-authored notes.

## WSL Proxy Warning

The message about localhost proxy configuration and NAT mode is a WSL warning. It does not by itself mean WeChat helpers failed.
