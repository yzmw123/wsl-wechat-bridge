# WSL WeChat Bridge

WSL WeChat Bridge is a local Windows + WSL2 helper toolkit for running Linux WeChat Desktop in a private nested desktop, with clipboard sync, Windows-side controls, and optional notification/focus helpers.

The current repo contains two layers:

- `app/`: the runnable code. This includes the Windows desktop clipboard widget, clipboard watcher, launcher scripts, and WSL/Linux helper commands.
- `skills/wsl-wechat-helper/`: an optional Codex skill for troubleshooting and maintenance. The app does not require this skill to run.

## What The Widget Does

The Windows desktop widget can:

- preview Windows clipboard text, images, and files;
- push the selected payload into the WSL/Linux clipboard;
- start and stop the WSL WeChat Desktop command;
- show whether the unified clipboard watcher is running;
- start or stop the unified clipboard watcher from the UI.

The unified clipboard watcher keeps one automatic loop for:

- Windows image/file clipboard to Linux WeChat;
- Linux/X11 text clipboard to Windows.

It intentionally avoids a separate `wechatclip2win --watch` process.

## Why Keep The Skill?

If you only want to use the tool, you do not need the skill.

The skill is useful when a coding agent needs to repair or inspect the setup later. It records the local architecture, common commands, troubleshooting checks, and safety rules such as not creating visible Windows Start Menu WeChat entries.

In other words:

- Widget = product surface for humans.
- Skill = maintenance memory for agents and maintainers.

## Requirements

- Windows 11 with WSL2.
- A WSL distro such as `Ubuntu-22.04`.
- Linux WeChat Desktop installed inside that distro.
- Linux packages used by the helper scripts, depending on which features you enable: `Xephyr`, `openbox`, `tint2`, `wmctrl`, `xdotool`, `xclip`, `dbus-x11`, `python3-dbus`, `python3-gi`, and `fcitx5`.

This project does not package or redistribute WeChat.

## Agent One-Click Install

If you use a local coding agent, copy the short prompt below and replace `<REPO_URL>` with this repository's GitHub URL:

```text
Please install WSL WeChat Bridge from <REPO_URL> on my Windows machine.

First inspect whether WSL2 and a usable Ubuntu distro are already installed. If WSL is missing or needs Windows features/reboot/admin changes, explain exactly what is needed and ask for my approval before changing the system. If WSL is ready, install or reuse Ubuntu-22.04 or another Ubuntu distro, install the latest official Linux WeChat package from https://linux.weixin.qq.com/, then install this bridge project.

After installation, start Linux WeChat through the bridge, open the Windows clipboard widget, verify Windows-to-WSL clipboard sync and Linux-WeChat-to-Windows text sync, and give me the daily commands. Do not use unofficial WeChat packages unless I explicitly approve.
```

See [docs/AGENT_INSTALL_PROMPT.md](docs/AGENT_INSTALL_PROMPT.md) for the full agent prompt.

## Manual Install

From an elevated or normal PowerShell session:

```powershell
cd path\to\wsl-wechat-bridge
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Distro Ubuntu-22.04
```

The installer copies Windows helpers to:

```powershell
%LOCALAPPDATA%\WslPrivate\launchers
```

It installs Linux commands into the WSL distro:

```text
/usr/local/bin
```

It also creates a desktop shortcut named `WSL剪切板同步.lnk` unless `-NoDesktopShortcut` is passed.

## Daily Commands

```powershell
wsl -d Ubuntu-22.04 -- wechat-desktop
wsl -d Ubuntu-22.04 -- wechat-desktop-status
wsl -d Ubuntu-22.04 -- wechat-desktop-stop
wsl -d Ubuntu-22.04 -- wechat-desktop-stop --force

wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-widget-hidden.vbs"
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\WslPrivate\launchers\clipboard-watch.ps1" -Status
```

## Repository Layout

```text
app/
  linux/bin/        WSL-side commands installed into /usr/local/bin
  windows/          WinForms widget, watchers, icon assets, Windows helper
  windows/launchers Hidden VBS/CMD entrypoints
docs/               Notes for users and maintainers
scripts/install.ps1 Installer for local use
skills/             Optional Codex skill
```

## Privacy Notes

The helper logs only operational metadata such as process IDs, byte counts, and hashes. It does not intentionally log clipboard contents.

Review the code before using it with sensitive accounts or files.
