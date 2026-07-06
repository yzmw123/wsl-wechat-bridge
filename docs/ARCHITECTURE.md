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

Optional Linux-side configuration lives under:

```text
~/.config/wsl-wechat-bridge/config
```

Supported keys:

```text
WECHAT_COMMAND=/path/to/wechat
```

The installer also creates convenience symlinks in the WSL home directory when the corresponding Windows paths are available:

```text
~/Windows-C
~/Windows-D
~/Windows-Desktop
~/Windows-Downloads
~/Windows-Documents
```

These links let Linux WeChat's file picker send files directly from Windows disks.

## Chinese Input

Fresh WSL/Ubuntu installs usually do not include a Chinese input method usable by Linux GUI apps. `wechat-desktop` exports fcitx5-related input-method variables and starts `fcitx5`, while the installer and doctor expect the distro to have `fcitx5`, `fcitx5-chinese-addons`, and `fcitx5-pinyin`.

If users can launch Linux WeChat but cannot type Chinese, check the input packages and `~/.cache/wechat-desktop/fcitx5.log` before debugging WeChat itself.

## Components

- `clipboard-widget.ps1`: WinForms desktop widget for manual clipboard preview and sync.
- `clipboard-watch.ps1`: unified automatic clipboard watcher.
- `winclip2wechat`: writes Windows clipboard text, image, or file URI payloads to the Linux clipboard.
- `wechatclip2win`: copies nested X11 text clipboard back to Windows.
- `focus-watch.ps1` and `wsl-app-focus-bridge`: keep Linux WeChat from always thinking it is foreground.
- `wsl-app-notify-bridge` and `wsl-app-notification-daemon`: forward Linux notification signals to Windows.
- `wsl-app-badge-notify-watch`: optional unread badge watcher for notification experiments.
- `scripts/doctor.ps1`: read-only public health check for WSL, helper files, dependencies, WeChat command detection, and Windows file links.

## Skill vs Widget

The widget is part of the product. The skill is not part of the runtime path.

Keep the skill in the repo when you want Codex or another agent to understand how to inspect and repair the setup. Omit the skill if you only want to package the end-user application.
