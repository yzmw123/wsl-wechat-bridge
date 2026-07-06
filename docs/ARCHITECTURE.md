# Architecture

## Main Flow

`wechat-desktop` starts a nested X display with Xephyr, then launches Linux WeChat inside that display. It also starts helper services when the Windows-side launcher scripts are present.

Windows helper scripts live under:

```powershell
%LOCALAPPDATA%\WslPrivate\launchers
```

Linux runtime state lives under:

```text
~/.cache/wechat-desktop
```

## Components

- `clipboard-widget.ps1`: WinForms desktop widget for manual clipboard preview and sync.
- `clipboard-watch.ps1`: unified automatic clipboard watcher.
- `winclip2wechat`: writes Windows clipboard text, image, or file URI payloads to the Linux clipboard.
- `wechatclip2win`: copies nested X11 text clipboard back to Windows.
- `focus-watch.ps1` and `wsl-app-focus-bridge`: keep Linux WeChat from always thinking it is foreground.
- `wsl-app-notify-bridge` and `wsl-app-notification-daemon`: forward Linux notification signals to Windows.
- `wsl-app-badge-notify-watch`: optional unread badge watcher for notification experiments.

## Skill vs Widget

The widget is part of the product. The skill is not part of the runtime path.

Keep the skill in the repo when you want Codex or another agent to understand how to inspect and repair the setup. Omit the skill if you only want to package the end-user application.
