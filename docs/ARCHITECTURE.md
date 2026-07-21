# Architecture

## Main Flow

`wechat-desktop` starts a nested X display with Xephyr, then launches Linux WeChat inside that display. It also starts helper services when the Windows-side launcher scripts are present.

The nested desktop is intentionally single-workspace. `wechat-desktop` generates a private openbox config under `~/.cache/wechat-desktop/openbox/rc.xml`, sets `<number>1</number>`, removes desktop-switch bindings from that runtime config, and enforces the live X11 desktop count as 1 with `wmctrl`/`xdotool` when available. This prevents mouse-wheel workspace switching from hiding WeChat on unused `desktop2-4` workspaces.

Windows helper scripts live under:

```powershell
%LOCALAPPDATA%\WslPrivate\launchers
```

The installer persists its validated WSL distribution name in `distro.txt` in this directory. Distro-aware VBS/CMD launchers prefer an explicit `WSL_WECHAT_DISTRO` override, then this file, then the `Ubuntu-22.04` fallback.

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

Fresh WSL/Ubuntu installs usually do not include a Chinese input method usable by Linux GUI apps. `wechat-desktop` exports fcitx input-method variables and starts fcitx4, while the installer and doctor expect the distro to have `fcitx` and `fcitx-pinyin`. A user-installed Debian/Ubuntu `sogoupinyin` 4.x package with its standard `/opt/sogoupinyin/files/bin` layout is also supported; the project does not redistribute or install that proprietary package.

Sogou uses POSIX message queues. Before starting an input method managed by this project, the launcher mounts `/dev/mqueue` with non-interactive sudo when needed, stops exact orphan Sogou service/watchdog processes, and removes only queues owned by the current uid and nested display. The managed fcitx PID is recorded so the stop command can shut down and clean up only this session. Check `wechat-desktop-status` and `~/.cache/wechat-desktop/fcitx5.log` (legacy filename) before debugging WeChat itself.

`wechat-input-reset` is intentionally a fcitx4/Sogou-specific recovery command, not a generic fcitx5/IBus reset. `--check` performs a read-only capability probe. A non-blocking `flock` lock prevents concurrent CLI or multi-widget resets. The reset uses `wechat-desktop-stop --force`, verifies that the old display is stably down and its scoped queues are gone, relaunches the same WSL distro through Windows interop, waits for display-scoped WeChat/fcitx/Sogou processes, selects `sogoupinyin`, and arms a bounded one-shot activator for the first focused Linux input. A controlled desktop restart is required because the proprietary fcitx4 Sogou addon retains old message-queue handles. The widget labels the action `重置搜狗输入法`, disables it when `--check` fails, and requires confirmation because unsent input can be lost.

## Components

- `clipboard-widget.ps1`: WinForms desktop widget for manual clipboard preview, sync, and runtime status.
- `wechat-input-reset`: performs a controlled restart of this nested WeChat desktop, clears scoped Sogou IPC queues, and switches the first focused Linux input back to Sogou.
- `clipboard-watch.ps1`: unified automatic clipboard watcher.
- `winclip2wechat`: writes Windows clipboard text, image, or file URI payloads to the Linux clipboard.
- `wechatclip2win`: copies nested X11 text clipboard back to Windows.
- `focus-watch.ps1` and `wsl-app-focus-bridge`: keep Linux WeChat from always thinking it is foreground.
- `wsl-app-notify-bridge` and `wsl-app-notification-daemon`: forward Linux notification signals to Windows. D-Bus/X11 signals use the normal popup setting; broad file activity is diagnostic only by default.
- `wsl-app-badge-notify-watch`: detects numeric unread badges for taskbar attention while ignoring plain red dots.
- `scripts/doctor.ps1`: read-only public health check for WSL, helper files, dependencies, WeChat command detection, and Windows file links.

## Process Lifecycle

`wechat-desktop` starts helper services without broad process cleanup. It does not kill existing `wechat`, `WeChatAppEx`, or fcitx processes during startup. It reuses only an fcitx process whose environment matches the managed `DISPLAY`, records that PID, and starts a new fcitx without `--replace` when the display has none. Sogou service/watchdog discovery is also filtered by `DISPLAY`. Immediately before `exec`-ing WeChat, it records the stable process ID in `wechat.pid`.

`wechat-desktop-stop` collects validated state-file PIDs. For WeChat, it uses `wechat.pid` plus descendants; old sessions without that file use an exact executable/name fallback filtered by the managed `DISPLAY`. It no longer stops all WeChat processes owned by the WSL user. Normal stop asks its display-scoped managed fcitx session to exit, sends `SIGTERM` to survivors, removes only that uid/display's Sogou queues, and returns non-zero if anything survives; `--force` is required before `SIGKILL` is used. The stop command also stops the Windows focus and clipboard watchers through their private launcher scripts.

## Logging And Privacy

Runtime logs rotate by default at 5 MB with two backups. The size and backup count can be changed with `WSL_WECHAT_LOG_MAX_BYTES` and `WSL_WECHAT_LOG_BACKUPS`.

Logs should contain operational metadata only: PIDs, counts, byte sizes, and hashes. Windows foreground titles, D-Bus notification summaries/bodies, clipboard text, and Windows file paths are not written by default. The status collector redacts legacy sensitive fields when tailing old logs.

Clipboard bridge payloads live under a private runtime/cache directory, not `~/Pictures`. Text and file-list payloads are written with restrictive permissions, copied into the target clipboard, and removed or expired by `WSL_WECHAT_CLIPBOARD_TTL_SECONDS`. `winclip2wechat` prints file paths only when `WSL_WECHAT_VERBOSE_CLIPBOARD=1` is set for debugging.

## Skill vs Widget

The widget is part of the product. The skill is not part of the runtime path.

Keep the skill in the repo when you want Codex or another agent to understand how to inspect and repair the setup. Omit the skill if you only want to package the end-user application.
