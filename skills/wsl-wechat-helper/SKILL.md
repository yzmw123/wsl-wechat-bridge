---
name: wsl-wechat-helper
description: Maintain a local WSL2 Linux WeChat Desktop helper setup. Use when the user asks about WSL WeChat/Desktop, wechat-desktop commands, Windows search hiding, clipboard sync to Linux WeChat, Windows notifications or taskbar flashing, Xephyr/openbox/tint2 nested desktop, stuck WeChat processes, or updating the local WSL WeChat docs and quick command sheet.
---

# WSL WeChat Helper

## Overview

Use this skill to maintain the user's local WSL2 Linux WeChat Desktop workflow. The setup intentionally avoids visible Windows Start/Search WeChat entries; the user normally starts it with `wsl -d Ubuntu-22.04 -- wechat-desktop`.

This is a local maintenance skill, not a generic public installer. Prefer preserving the user's current working setup and docs over re-creating everything from scratch.

## First Checks

1. Inspect current status before changing anything:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\wsl-wechat-helper\scripts\collect-status.ps1 -Distro Ubuntu-22.04
```

For public repo installs, also prefer the project doctor when available:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -Distro Ubuntu-22.04
```

2. If the task is about commands or documentation, read `references/commands.md`.
3. If the task is about paths, helper files, or architecture, read `references/local-layout.md`.
4. If the task is about a broken notification, clipboard sync, process stop, or Windows search leak, read `references/troubleshooting.md`.

## Safety Rules

- Do not hide or delete project documentation or user-authored notes while hiding Windows app/search entries.
- Do not create visible Windows Start Menu entries or WeChat-named Windows shortcuts unless the user explicitly requests it.
- Keep helper scripts under `%LOCALAPPDATA%\WslPrivate\launchers` when Windows-side launchers are needed.
- Do not stop the active WeChat session unless the user asks to close it, the task is specifically about stuck processes, or a restart is necessary and clearly explained.
- Avoid broad `pkill -f` cleanup patterns. Prefer installed commands such as `wechat-desktop-stop` or exact process matching.
- Preserve privacy defaults: logs should record counts, sizes, hashes, PIDs, and states, not clipboard contents, Windows foreground titles, D-Bus notification summaries/bodies, or Windows file paths.
- Treat `BADGE_WATCH_ENABLED=1` as the default healthy state. The watcher analyzes the left portion of the WeChat window for numeric unread badges and can be disabled when periodic screenshot analysis is not desired.
- Normal `wechat-desktop-stop` should use graceful termination and report survivors. Use `--force` only when the user accepts `SIGKILL`.
- Treat the WSL message `localhost proxy ... NAT mode ...` as benign unless the user asks about networking.

## Common Tasks

### Show or Update Quick Commands

Use `README.md` and `docs/` as the project documentation. Keep daily commands short and practical.

### Start, Stop, and Status

Prefer the installed commands from `references/commands.md`:

```powershell
wsl -d Ubuntu-22.04 -- wechat-desktop
wsl -d Ubuntu-22.04 -- wechat-desktop-status
wsl -d Ubuntu-22.04 -- wechat-input-reset --check
wsl -d Ubuntu-22.04 -- wechat-input-reset
wsl -d Ubuntu-22.04 -- wechat-desktop-stop
wsl -d Ubuntu-22.04 -- wechat-desktop-stop --force
```

`wechat-desktop-status` also reports runtime config defaults such as `badge_watch_enabled`, log rotation limits, and clipboard temporary payload TTL.

### Nested Desktop Workspaces

The Xephyr/openbox/tint2 desktop is intentionally fixed to one workspace, `desktop1`. `wechat-desktop` generates private openbox/tint2 configs under `~/.cache/wechat-desktop` and enforces the live X11 desktop count as 1. If the user reports scrolling into `desktop2-4`, check `references/local-layout.md`, verify `wmctrl -d` on the nested display, and avoid stopping WeChat unless a full restart is clearly needed.

### Notification Bridge

The notification bridge should flash the Windows taskbar entry for the nested WeChat Desktop window. The small Windows popup is optional and is disabled by default; the widget's `消息弹窗` checkbox writes `%LOCALAPPDATA%\WslPrivate\launchers\settings.json` with `NoticePopupEnabled`. The bridge trusts WeChat's X11/D-Bus signals and the numeric unread badge watcher. Broad WeChat message/session file activity defaults to `log-only` because official accounts, service accounts, muted conversations, cross-device sync, and self-sent messages also change those files.

Use:

```powershell
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge --status
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge --test
wsl -d Ubuntu-22.04 -- wsl-app-notify-bridge-restart
```

If `--test` logs the request but no taskbar flash appears, read `references/troubleshooting.md` before editing scripts. A missing popup is expected when `NoticePopupEnabled` is false. The working bridge uses a Windows PowerShell `Start-Process` parent command and passes the helper path via `WSLENV=WSL_NOTICE_HELPER`.

If manual `--test` works but real messages do not, check `wsl-app-notify-bridge --status`, `~/.cache/wechat-desktop/notification-daemon.log`, and `~/.cache/wechat-desktop/badge-notify-watch.log`. Real alerts should normally show as `dbus-notify`, X11 attention/title signals, new WeChat windows, or `notify reason=numeric-badge`. D-Bus logs intentionally use lengths and hashes instead of notification summary/body text.

The unread badge watcher is enabled by default and can be disabled with `BADGE_WATCH_ENABLED=0` in `~/.config/wsl-wechat-bridge/config`. It requires a red badge with interior light digit pixels; plain red dots do not trigger taskbar attention.

### Focus Bridge

The focus bridge changes WeChat's Linux foreground judgment in real time. When the Windows foreground window is not WeChat Desktop, the Windows watcher focuses a tiny Linux `wsl-focus-sink` window so WeChat is no longer the X11 active window. `wechat-desktop` starts it automatically.

Use:

```powershell
wsl -d Ubuntu-22.04 -- wsl-app-focus-bridge --status
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-focus-watch-hidden.vbs"
& "$env:LOCALAPPDATA\WslPrivate\launchers\stop-focus-watch.cmd"
Get-Content "$env:LOCALAPPDATA\WslPrivate\launchers\focus-watch.log" -Tail 60
```

When Windows foreground is not WeChat Desktop, `wsl-app-focus-bridge --status` should show `active_name=wsl-focus-sink`.

### Clipboard Sync

Use:

```powershell
wsl -d Ubuntu-22.04 -- winclip2wechat
wsl -d Ubuntu-22.04 -- winclip2wechat --paste
wsl -d Ubuntu-22.04 -- wechatclip2win
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-widget-hidden.vbs"
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-watch-hidden.vbs"
& "$env:LOCALAPPDATA\WslPrivate\launchers\stop-clipboard-watch.cmd"
```

`start-clipboard-widget-hidden.vbs` opens the manual Windows clipboard widget. The widget can preview/edit text, preview images, list copied or dropped files, and then push that payload to the WSL/Linux clipboard by calling `winclip2wechat`. Its `剪贴板` page bottom row has two side-by-side buttons: `同步到 WSL` and the manual WSL-to-Windows text sync button `读取WSL剪切板`. It also has app controls that call `wechat-desktop`, `wechat-desktop-stop`, and `wechat-input-reset`; the `重置搜狗输入法` button is enabled only when the read-only `--check` confirms fcitx4 + Sogou 4.x, warns before restarting, cleans scoped Sogou queues, and switches the first focused Linux input back to Sogou.

The widget has a dedicated `运行状态` page with the unified clipboard watcher status, a green/yellow indicator, a status-aware `启动监听` / `停止监听` button, a small yellow/green status dot in the `运行状态` tab, and recent operation output.

`start-clipboard-watch-hidden.vbs` starts the single unified bidirectional watcher: Windows image/file clipboard to Linux WeChat, and Linux WeChat/X11 text clipboard to Windows. Do not start `wechatclip2win --watch` as a separate watcher.

`wechat-desktop` also starts this unified clipboard watcher automatically when the helper is present, so the user's normal start command should restore clipboard sync after reboot or app restart.

Clipboard payload files are temporary. They live under a private runtime/cache directory, are written with restricted permissions, and expire according to `WSL_WECHAT_CLIPBOARD_TTL_SECONDS` (default 3600). `winclip2wechat` does not print Windows file paths unless `WSL_WECHAT_VERBOSE_CLIPBOARD=1` is set for debugging.

### Chinese Input Method

Fresh WSL/Ubuntu installs usually do not have Chinese input ready for Linux GUI apps. `wechat-desktop` exports fcitx input-method environment variables and starts fcitx4, with `fcitx-pinyin` as the baseline engine and a user-installed Debian/Ubuntu Sogou Pinyin 4.x package supported when it uses the standard `/opt/sogoupinyin/files/bin` layout. The project does not install or redistribute Sogou. Sogou also needs `/dev/mqueue`; the launcher mounts it when possible and removes stale queues scoped to the current uid/display. If Chinese input is missing or slow, check `wechat-desktop-status` and `~/.cache/wechat-desktop/fcitx5.log` (legacy filename), and verify repeated conversion latency rather than only one successful conversion.

When WeChat is already running but Sogou is delayed or stuck, run `wechat-input-reset --check` first, then use `wechat-input-reset` or the widget's `重置搜狗输入法` button. This is not a generic fcitx5, IBus, or other-engine reset. It intentionally restarts this managed nested desktop because deleting Sogou queues while preserving fcitx leaves the proprietary addon attached to old queue handles. The helper uses a concurrency lock, validated managed PID/display scope, current-uid/current-display queue cleanup, same-distro relaunch, and first-input activation. Warn that unsent input should be saved first.

### Windows File Links

For sending Windows files directly from Linux WeChat, and for saving received files back into Windows folders, the installer creates WSL home links such as `~/Windows-C`, `~/Windows-D`, `~/Windows-Downloads`, `~/Windows-Desktop`, and `~/Windows-Documents`. If the official WeChat package installs a nonstandard command, set `WECHAT_COMMAND=/path/to/wechat` in `~/.config/wsl-wechat-bridge/config`.

### Windows Search Hiding

When hiding WeChat from Windows search, remove WSLg-exported `.lnk` files and move Linux `.desktop` files out of exported application directories. Do not hide project documentation or user-authored notes.

## Local References

- `references/commands.md`: daily commands and doc paths.
- `references/local-layout.md`: installed scripts, state paths, component map.
- `references/troubleshooting.md`: repair patterns and known gotchas.
- `scripts/collect-status.ps1`: read-only status collection script.
