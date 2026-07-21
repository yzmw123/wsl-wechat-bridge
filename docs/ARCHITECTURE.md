# Architecture

## Main Flow

`wechat-desktop` starts a nested X display with Xephyr, then launches Linux WeChat inside that display. It also starts helper services when the Windows-side launcher scripts are present.

The nested desktop is intentionally single-workspace. `wechat-desktop` generates a private openbox config under `~/.cache/wechat-desktop/openbox/rc.xml`, sets `<number>1</number>`, removes desktop-switch bindings from that runtime config, and enforces the live X11 desktop count as 1 with `wmctrl`/`xdotool` when available. This prevents mouse-wheel workspace switching from hiding WeChat on unused `desktop2-4` workspaces.

Windows helper scripts live under:

```powershell
%LOCALAPPDATA%\WslPrivate\launchers
```

Linux runtime state lives under:

```text
~/.cache/wechat-desktop
```

Optional Linux-side configuration lives under:

```text
~/.config/wsl-wechat-bridge/config
```

Supported keys:

```text
WECHAT_COMMAND=/path/to/wechat
NOTICE_BRIDGE_ENABLED=1
FOCUS_WATCH_ENABLED=1
CLIPBOARD_WATCH_ENABLED=1
BADGE_WATCH_ENABLED=1
BADGE_WATCH_POLL_SECONDS=3
BADGE_WATCH_IDLE_POLL_SECONDS=10
WSL_WECHAT_LOG_MAX_BYTES=5242880
WSL_WECHAT_LOG_BACKUPS=2
WSL_WECHAT_CLIPBOARD_TTL_SECONDS=3600
```

`NOTICE_BRIDGE_ENABLED`, `FOCUS_WATCH_ENABLED`, `CLIPBOARD_WATCH_ENABLED`, and `BADGE_WATCH_ENABLED` default to enabled. The badge watcher periodically analyzes only the left portion of the WeChat window and can be disabled when screenshot polling is not desired.

The installer also creates convenience symlinks in the WSL home directory when the corresponding Windows paths are available:

```text
~/Windows-C
~/Windows-D
~/Windows-Desktop
~/Windows-Downloads
~/Windows-Documents
```

These links let Linux WeChat's file picker send files directly from Windows disks and save received files back into Windows folders.

## Chinese Input

Fresh WSL/Ubuntu installs usually do not include a Chinese input method usable by Linux GUI apps. `wechat-desktop` exports fcitx input-method variables and starts fcitx4, while the installer and doctor expect the distro to have `fcitx` and `fcitx-pinyin`. An installed Sogou Pinyin 4.x engine is also supported.

Sogou uses POSIX message queues. Before starting an input method managed by this project, the launcher mounts `/dev/mqueue` with non-interactive sudo when needed, stops exact orphan Sogou service/watchdog processes, and removes only queues owned by the current uid and nested display. The managed fcitx PID is recorded so the stop command can shut down and clean up only this session. Check `wechat-desktop-status` and `~/.cache/wechat-desktop/fcitx5.log` (legacy filename) before debugging WeChat itself.

## Components

- `clipboard-widget.ps1`: WinForms desktop widget for manual clipboard preview, sync, and runtime status.
- `clipboard-watch.ps1`: unified automatic clipboard watcher.
- `winclip2wechat`: writes Windows clipboard text, image, or file URI payloads to the Linux clipboard.
- `wechatclip2win`: copies nested X11 text clipboard back to Windows.
- `focus-watch.ps1` and `wsl-app-focus-bridge`: keep Linux WeChat from always thinking it is foreground.
- `wsl-app-notify-bridge` and `wsl-app-notification-daemon`: forward Linux notification signals to Windows. D-Bus/X11 signals use the normal popup setting; broad file activity is diagnostic only by default.
- `wsl-app-badge-notify-watch`: detects numeric unread badges for taskbar attention while ignoring plain red dots.
- `scripts/doctor.ps1`: read-only public health check for WSL, helper files, dependencies, WeChat command detection, and Windows file links.

## Process Lifecycle

`wechat-desktop` starts helper services without broad process cleanup. It does not kill existing `wechat`, `WeChatAppEx`, or fcitx processes during startup. fcitx is started only when it is not already running for the user; exact orphan Sogou service/watchdog processes are stopped only when no fcitx process exists and a new managed input session is about to start.

`wechat-desktop-stop` collects PIDs from state files plus exact user-process matches. Normal stop asks its managed fcitx session to exit, sends `SIGTERM` to survivors, removes its Sogou queues, and returns non-zero if anything survives; `--force` is required before `SIGKILL` is used. The stop command also stops the Windows focus and clipboard watchers through their private launcher scripts, with command-line validation before terminating PID-file processes.

## Logging And Privacy

Runtime logs rotate by default at 5 MB with two backups. The size and backup count can be changed with `WSL_WECHAT_LOG_MAX_BYTES` and `WSL_WECHAT_LOG_BACKUPS`.

Logs should contain operational metadata only: PIDs, counts, byte sizes, and hashes. Windows foreground titles, D-Bus notification summaries/bodies, clipboard text, and Windows file paths are not written by default. The status collector redacts legacy sensitive fields when tailing old logs.

Clipboard bridge payloads live under a private runtime/cache directory, not `~/Pictures`. Text and file-list payloads are written with restrictive permissions, copied into the target clipboard, and removed or expired by `WSL_WECHAT_CLIPBOARD_TTL_SECONDS`. `winclip2wechat` prints file paths only when `WSL_WECHAT_VERBOSE_CLIPBOARD=1` is set for debugging.

## Skill vs Widget

The widget is part of the product. The skill is not part of the runtime path.

Keep the skill in the repo when you want Codex or another agent to understand how to inspect and repair the setup. Omit the skill if you only want to package the end-user application.
