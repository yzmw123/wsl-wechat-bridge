# Local Layout

## WSL Distro

- Distro: `Ubuntu-22.04`
- Main user command: `wsl -d Ubuntu-22.04 -- wechat-desktop`
- Nested X display: usually `:20`
- State directory: `~/.cache/wechat-desktop`
- Config file: `~/.config/wsl-wechat-bridge/config`

Optional config keys:

```text
WECHAT_COMMAND=/path/to/wechat
NOTICE_BRIDGE_ENABLED=1
FOCUS_WATCH_ENABLED=1
CLIPBOARD_WATCH_ENABLED=1
BADGE_WATCH_ENABLED=0
BADGE_WATCH_POLL_SECONDS=3
BADGE_WATCH_IDLE_POLL_SECONDS=10
WSL_WECHAT_LOG_MAX_BYTES=5242880
WSL_WECHAT_LOG_BACKUPS=2
WSL_WECHAT_CLIPBOARD_TTL_SECONDS=3600
```

`BADGE_WATCH_ENABLED` is intentionally disabled by default. `wechat-desktop-status` prints the effective defaults so diagnostics can distinguish a disabled optional watcher from a failed one.

## Nested Desktop

`wechat-desktop` runs Linux WeChat inside Xephyr/openbox/tint2 on the nested display. The openbox runtime is fixed to a single workspace:

- private openbox config: `~/.cache/wechat-desktop/openbox/rc.xml`
- private tint2 config: `~/.cache/wechat-desktop/tint2/tint2rc`
- active workspace count: `1`, named `desktop1`

The generated openbox config sets `<number>1</number>`, disables the desktop switch popup, and removes desktop-switch key/mouse bindings from that private config. Startup and `wechat-restore` also enforce the live X11 desktop count as 1 with `wmctrl` or `xdotool` when available, so mouse-wheel scrolling cannot send the user to unused `desktop2-4` workspaces.

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
- `wsl-app-badge-notify-watch`
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
- D-Bus notification logs use `app_len`, `app_hash`, `summary_len`, `summary_hash`, and `body_len`; they must not include summary/body text.
- `%LOCALAPPDATA%\WslPrivate\launchers\notice.log` should show `start`, `title_chars`, `body_chars`, `flashed=1`, `popup=disabled` when popups are off, and later `done`.
- The helper matches Windows titles containing `WeChat Desktop` or `Ubuntu-22.04`.
- Message popup windows are disabled by default. The widget's `消息弹窗` checkbox controls `%LOCALAPPDATA%\WslPrivate\launchers\settings.json` and the `NoticePopupEnabled` value; taskbar flashing remains enabled either way.
- The real Windows taskbar title may look like `[WARN:COPY MODE] WeChat Desktop (Ubuntu-22.04)`.

Implementation gotcha:

- Passing a Windows path from WSL to Windows PowerShell is fragile.
- The current working approach passes the helper path through `WSL_NOTICE_HELPER` and exports it with `WSLENV=WSL_NOTICE_HELPER`, then a parent `powershell.exe` calls `Start-Process`.
- Real WeChat messages may use the standard Linux D-Bus notification interface. The local `wsl-app-notification-daemon` owns `org.freedesktop.Notifications` on WeChat's session bus and forwards those notifications to the Windows helper.
- Some real messages do not emit D-Bus notifications or X11 window signals. The daemon watches WeChat message/session storage file activity only for diagnosis in default `log-only` mode. It does not read message contents and does not use file activity for Windows notices by default, because file writes include muted groups, official accounts, service accounts, cross-device sync, and self-sent messages.
- A legacy file-activity notice mode can be enabled only deliberately with `WSL_WECHAT_FILE_ACTIVITY_NOTICE_MODE=notify`; in that mode `focus-watch.ps1` writes `%LOCALAPPDATA%\WslPrivate\launchers\focus-watch.state` and the notification daemon suppresses file-activity notices while Windows foreground is WeChat Desktop.
- The optional `wsl-app-badge-notify-watch` watcher is started only when `BADGE_WATCH_ENABLED=1`. It uses `BADGE_WATCH_POLL_SECONDS` while active and `BADGE_WATCH_IDLE_POLL_SECONDS` when idle.

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

- `focus-watch.ps1` polls the Windows foreground title in memory. If the title contains `WeChat Desktop`, it focuses WeChat inside the nested X display; otherwise it focuses the tiny `wsl-focus-sink` window.
- While Windows foreground is not WeChat Desktop, the watcher re-enforces the hidden sink every few seconds so a Linux-side focus steal does not leave WeChat active.
- The watcher writes `focus-watch.state` with only `timestamp` and `state=active` or `state=inactive`; it must not persist the foreground window title. The notification daemon only needs this if legacy file-activity notice mode is deliberately re-enabled.
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

The widget has two pages. The `剪贴板` page previews or edits Windows clipboard payloads, then calls `winclip2wechat` to write the selected payload into the Linux/X11 clipboard. Its bottom row has two side-by-side buttons: `同步到 WSL` and `读取WSL剪切板`; the second button manually pulls Linux/X11 text back to Windows with `wechatclip2win`. The `运行状态` page shows the unified clipboard watcher status, a green/yellow indicator, a status-aware `启动监听` / `停止监听` button, a small yellow/green status dot in the `运行状态` tab, and recent operation output. It also has `启动应用` and `关闭应用` controls for `wechat-desktop` and `wechat-desktop-stop`. A desktop shortcut named `WSL剪切板同步.lnk` may point to this VBS launcher and use `wsl-clip-cube.ico`.

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

`wechat-desktop` starts the unified clipboard watcher automatically when the Windows helper exists and `CLIPBOARD_WATCH_ENABLED` is not disabled, so the normal start command restores clipboard sync after reboot or app restart. `wechat-desktop-stop` stops it to avoid orphan Windows polling after the nested desktop exits.

Clipboard payload files live under a private runtime/cache directory such as `$XDG_RUNTIME_DIR/wsl-wechat-bridge` or `~/.cache/wechat-desktop/runtime/wsl-wechat-bridge`. They are mode-restricted and expire according to `WSL_WECHAT_CLIPBOARD_TTL_SECONDS`. `winclip2wechat` prints file paths only when `WSL_WECHAT_VERBOSE_CLIPBOARD=1` is set.

`wechatclip2win --watch` should not be used as a separate watcher. The `start-linux-clipboard-watch-hidden.vbs` and `stop-linux-clipboard-watch.cmd` helpers remain only as compatibility aliases to the unified watcher.

## Stop Semantics

Normal `wechat-desktop-stop` sends `SIGTERM` and returns non-zero if matching processes survive. `--force` is required for `SIGKILL`. PID files are used only after command-line validation, and the notification daemon PID is included in dry-run and stop matching.

Windows `stop-focus-watch.cmd` and `stop-clipboard-watch.cmd` also validate that the PID-file process command line matches the expected watcher before stopping it.

## Logs

Linux and Windows helper logs rotate by default at 5 MB with two backups. Logs should contain operational metadata only: counts, byte sizes, hashes, PIDs, states, and launch outcomes.

## User Docs

Project docs:

- `README.md`
- `docs/`
- `scripts/doctor.ps1`

Do not hide these files while hiding Windows app/search entries.
