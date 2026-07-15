# Local Layout

## WSL Distro

- Distro: `Ubuntu-22.04`
- Main user command: `wsl -d Ubuntu-22.04 -- wechat-desktop`
- Nested X display: usually `:20`
- State directory: `~/.cache/wechat-desktop`
- Config file: `~/.config/wsl-wechat-bridge/config`

Optional config key:

```text
WECHAT_COMMAND=/path/to/wechat
```

## Windows File Links

The installer creates convenience links in the WSL home directory when the Windows paths are mounted:

- `~/Windows-C`
- `~/Windows-D`
- `~/Windows-Desktop`
- `~/Windows-Downloads`
- `~/Windows-Documents`

These make Windows files visible in Linux WeChat's file picker, so users can send files from Windows disks directly and save received files back into Windows folders.

## Chinese Input Method

`wechat-desktop` sets these environment variables before launching Linux WeChat:

- `XMODIFIERS=@im=fcitx`
- `GTK_IM_MODULE=fcitx`
- `QT_IM_MODULE=fcitx`

It also starts `fcitx5` and writes logs to `~/.cache/wechat-desktop/fcitx5.log`.

Fresh WSL/Ubuntu installs still need Chinese input engine packages installed, typically:

- `fcitx5`
- `fcitx5-chinese-addons`
- `fcitx5-pinyin`

## Linux Commands

Installed under `/usr/local/bin`:

- `wechat-desktop`
- `wechat-desktop-status`
- `wechat-desktop-stop`
- `wechat-restore`
- `winclip2wechat`
- `wechatclip2win`
- `wsl-app-notify-bridge`
- `wsl-app-notify-bridge-restart`
- `wsl-app-notification-daemon`
- `wsl-app-focus-bridge`
- `wsl-focus-sink`

## Windows Helper Directory

Windows helper scripts live under:

```powershell
$env:LOCALAPPDATA\WslPrivate\launchers
```

Known helper files:

- `start-app-hidden.vbs`
- `stop-app-hidden.vbs`
- `restore-hidden.vbs`
- `paste-hidden.vbs`
- `paste.cmd`
- `clipboard-watch.ps1`
- `clipboard-widget.ps1`
- `start-clipboard-widget-hidden.vbs`
- `start-clipboard-widget.cmd`
- `wsl-clip-cube.svg`
- `wsl-clip-cube.png`
- `wsl-clip-cube.ico`
- `start-clipboard-watch-hidden.vbs`
- `start-clipboard-watch.cmd`
- `stop-clipboard-watch.cmd`
- `start-linux-clipboard-watch-hidden.vbs` (compatibility alias for the unified clipboard watcher)
- `stop-linux-clipboard-watch.cmd` (compatibility alias for the unified clipboard watcher)
- `focus-watch.ps1`
- `start-focus-watch-hidden.vbs`
- `stop-focus-watch.cmd`
- `notice.ps1`
- `notice.log`
- `settings.json` (local runtime settings, including `NoticePopupEnabled`)

Keep these helpers in the private launcher directory. Avoid creating visible WeChat-named Windows launchers.

## Notification Bridge

Bridge command:

```powershell
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge --status
```

Working behavior:

- `--test` should return quickly, around 1 second.
- `--status` should show both `running ... display=:20` and `notification_daemon=running ...`.
- `~/.cache/wechat-desktop/notice-bridge.log` should show `launch=start-process`.
- `~/.cache/wechat-desktop/notification-daemon.log` should show `started ...`, `file-watch started ...`, and `file-notice-mode=log-only`. It shows `dbus-notify ...` when Linux notifications arrive and `file-activity ...` when the diagnostic message/session storage watcher sees activity. In default `log-only` mode, file activity is logged but does not send Windows notices.
- `%LOCALAPPDATA%\WslPrivate\launchers\notice.log` should show `start`, `flashed=1`, `popup=disabled` when popups are off, and later `done`.
- The helper matches Windows titles containing `WeChat Desktop` or `Ubuntu-22.04`.
- Message popup windows are disabled by default. The widget's `消息弹窗` checkbox controls `%LOCALAPPDATA%\WslPrivate\launchers\settings.json` and the `NoticePopupEnabled` value; taskbar flashing remains enabled either way.
- The real Windows taskbar title may look like `[WARN:COPY MODE] WeChat Desktop (Ubuntu-22.04)`.

Implementation gotcha:

- Passing a Windows path from WSL to Windows PowerShell is fragile.
- The current working approach passes the helper path through `WSL_NOTICE_HELPER` and exports it with `WSLENV=WSL_NOTICE_HELPER`, then a parent `powershell.exe` calls `Start-Process`.
- Real WeChat messages may use the standard Linux D-Bus notification interface. The local `wsl-app-notification-daemon` owns `org.freedesktop.Notifications` on WeChat's session bus and forwards those notifications to the Windows helper.
- Some real messages do not emit D-Bus notifications or X11 window signals. The daemon watches WeChat message/session storage file activity only for diagnosis in default `log-only` mode. It does not read message contents and does not use file activity for Windows notices by default, because file writes include muted groups, official accounts, service accounts, cross-device sync, and self-sent messages.
- A legacy file-activity notice mode can be enabled only deliberately with `WSL_WECHAT_FILE_ACTIVITY_NOTICE_MODE=notify`; in that mode `focus-watch.ps1` writes `%LOCALAPPDATA%\WslPrivate\launchers\focus-watch.state` and the notification daemon suppresses file-activity notices while Windows foreground is WeChat Desktop.

## Focus Bridge

The real-time foreground/focus bridge keeps Linux WeChat from being treated as foreground while the user is working elsewhere in Windows.

Commands:

```powershell
wsl -d Ubuntu-22.04 -- wsl-app-focus-bridge --status
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-focus-watch-hidden.vbs"
& "$env:LOCALAPPDATA\WslPrivate\launchers\stop-focus-watch.cmd"
Get-Content "$env:LOCALAPPDATA\WslPrivate\launchers\focus-watch.log" -Tail 60
```

Working behavior:

- `focus-watch.ps1` polls the Windows foreground title. If the title contains `WeChat Desktop`, it focuses WeChat inside the nested X display; otherwise it focuses the tiny `wsl-focus-sink` window.
- While Windows foreground is not WeChat Desktop, the watcher re-enforces the hidden sink every few seconds so a Linux-side focus steal does not leave WeChat active.
- The watcher writes `focus-watch.state` with `state=active` or `state=inactive`; the notification daemon only needs this if legacy file-activity notice mode is deliberately re-enabled.
- `wsl-app-focus-bridge --status` should show `active_name=wsl-focus-sink` when Windows foreground is not the WeChat Desktop window.
- `wechat-desktop` starts the focus watcher automatically; `wechat-desktop-stop` stops it.

## Clipboard Bridge

Windows-to-Linux manual sync command. It supports text, images, and copied files:

```powershell
wsl -d Ubuntu-22.04 -- winclip2wechat
```

Manual Windows widget:

```powershell
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-widget-hidden.vbs"
```

The widget previews or edits Windows clipboard payloads, then calls `winclip2wechat` to write the selected payload into the Linux/X11 clipboard. It also has a manual WSL-to-Windows text sync button that calls `wechatclip2win`, `启动应用` and `关闭应用` buttons for `wechat-desktop` and `wechat-desktop-stop`, plus a green/yellow unified clipboard watcher status and status-aware `启动监听` / `停止监听` button. A desktop shortcut named `WSL剪切板同步.lnk` may point to this VBS launcher and use `wsl-clip-cube.ico`.

The widget icon uses a multi-size ICO generated from `clipboard-widget.ps1`; the shortcut should use an absolute `IconLocation`, not `%USERPROFILE%...`. The WinForms process sets an explicit AppUserModelID and sends both small and big window icons so the Windows taskbar does not fall back to a blank PowerShell/script placeholder.

Sync and paste into the active nested X11 window:

```powershell
wsl -d Ubuntu-22.04 -- winclip2wechat --paste
```

Linux-to-Windows manual sync command:

```powershell
wsl -d Ubuntu-22.04 -- wechatclip2win
```

Unified bidirectional watcher helpers:

- Start: `%LOCALAPPDATA%\WslPrivate\launchers\start-clipboard-watch-hidden.vbs`
- Stop: `%LOCALAPPDATA%\WslPrivate\launchers\stop-clipboard-watch.cmd`
- Status: `powershell -NoProfile -STA -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\WslPrivate\launchers\clipboard-watch.ps1" -Status`
- Log: `%LOCALAPPDATA%\WslPrivate\launchers\clipboard-watch.log`

`clipboard-watch.ps1` is the only automatic watcher. It preserves Windows-to-Linux image/file sync via `winclip2wechat` and also polls the nested X11 clipboard for Linux-to-Windows text sync via `wechatclip2win --probe`. It initializes the Linux clipboard hash on startup so it does not immediately overwrite the Windows clipboard with stale Linux content. It intentionally logs only byte/character counts and hashes, not clipboard contents.

`wechat-desktop` starts the unified clipboard watcher automatically when the Windows helper exists, so the normal start command restores clipboard sync after reboot or app restart.

`wechatclip2win --watch` should not be used as a separate watcher. The `start-linux-clipboard-watch-hidden.vbs` and `stop-linux-clipboard-watch.cmd` helpers remain only as compatibility aliases to the unified watcher.

## User Docs

Project docs:

- `README.md`
- `docs/`
- `scripts/doctor.ps1`

Do not hide these files while hiding Windows app/search entries.
