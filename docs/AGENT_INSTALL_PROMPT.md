# Agent Install Prompt

Copy the prompt below into Codex, Claude Code, Cursor Agent, or another local coding agent that can run shell commands on your Windows machine.

Repository URL:

```text
https://github.com/yzmw123/wsl-wechat-bridge
```

## Short Prompt

```text
Please install WSL WeChat Bridge from https://github.com/yzmw123/wsl-wechat-bridge on my Windows machine.

Please first read and follow the full agent install prompt:
https://github.com/yzmw123/wsl-wechat-bridge/blob/main/docs/AGENT_INSTALL_PROMPT.md

First inspect whether WSL2 and a usable Ubuntu distro are already installed. If WSL is missing or needs Windows features/reboot/admin changes, explain exactly what is needed and ask for my approval before changing the system. If WSL is ready, install or reuse Ubuntu-22.04 or another Ubuntu distro, install the latest official Linux WeChat package from https://linux.weixin.qq.com/, then install this bridge project.

After installation, run `scripts\doctor.ps1`, start Linux WeChat through the bridge, verify Chinese input works inside Linux WeChat, open the Windows clipboard widget, verify Windows-to-WSL clipboard sync, Linux-WeChat-to-Windows text sync, and that Linux WeChat can pick and save Windows files through `~/Windows-Downloads` or similar links. Give me the daily commands. Do not use unofficial WeChat packages unless I explicitly approve.
```

## Full Prompt

```text
You are my local installation agent. Your goal is to install and verify WSL WeChat Bridge from https://github.com/yzmw123/wsl-wechat-bridge so that I can run Linux WeChat inside WSL on Windows, chat normally, and have reliable clipboard sync between Windows and Linux WeChat.

Important safety rules:
- Inspect first; do not make destructive changes.
- Ask for my approval before enabling Windows features, installing WSL, rebooting Windows, running elevated/admin commands, or using sudo in WSL.
- Prefer the official Linux WeChat download page: https://linux.weixin.qq.com/
- Do not use unofficial WeChat packages, Flatpak wrappers, mirrors, or third-party repacks unless I explicitly approve.
- Do not log or print my clipboard contents or WeChat message contents.
- If you create Windows shortcuts, do not create visible Windows Start Menu entries named WeChat/微信 unless I explicitly ask.

Work step by step:

1. Check the Windows and WSL state.
   - Run `wsl --status` and `wsl -l -v`.
   - Confirm WSL2 is available.
   - If WSL is not installed, tell me the recommended command, usually `wsl --install -d Ubuntu-22.04`, and ask for approval. Explain that a Windows restart may be required.
   - If no Ubuntu distro exists, ask whether to install `Ubuntu-22.04` or use an existing distro.
   - If a distro exists but is WSL1, ask before converting it with `wsl --set-version <Distro> 2`.

2. Prepare the Ubuntu/WSL distro.
   - Choose the distro name, defaulting to `Ubuntu-22.04` if present.
   - Update package metadata.
   - Install required helper packages for this bridge, such as `x11-utils`, `x11-apps`, `xclip`, `wmctrl`, `xdotool`, `xserver-xephyr`, `openbox`, `tint2`, `dbus-x11`, `fcitx5`, `fcitx5-chinese-addons`, `fcitx5-pinyin`, `python3`, `python3-dbus`, and `python3-gi`.
   - Remember that a fresh WSL/Ubuntu distro usually has no usable Chinese input method for Linux GUI apps. Do not skip the fcitx5 Chinese engine packages; plain `fcitx5` alone may not be enough for pinyin input.
   - If package names differ for the distro, adapt and explain.

3. Install or update official Linux WeChat.
   - Check whether WeChat is already installed inside WSL with commands such as `command -v wechat`, `dpkg -l | grep -i wechat`, and `/usr/bin/wechat --version` if available.
   - If WeChat is missing or outdated, open or fetch the official Linux WeChat page at `https://linux.weixin.qq.com/`.
   - Select the latest package that matches the WSL distro and architecture. For Ubuntu/Debian on x86_64, prefer the official `.deb` package.
   - Download the package only from the official Tencent/WeChat download target linked by that page.
   - Install it in WSL, usually with `sudo apt install ./downloaded-package.deb` or `sudo dpkg -i ... && sudo apt -f install`.
   - Verify that the `wechat` command exists.
   - If the official package installs WeChat under a different command path, create `~/.config/wsl-wechat-bridge/config` with `WECHAT_COMMAND=/path/to/wechat`.

4. Install WSL WeChat Bridge from the repository.
   - Clone `https://github.com/yzmw123/wsl-wechat-bridge` into a reasonable local folder.
   - Run the project's installer from PowerShell:
     `powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Distro <DistroName>`
     If required dependencies are missing and I approve sudo changes, use:
     `powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Distro <DistroName> -InstallDependencies`
   - Confirm Windows helper files exist under `%LOCALAPPDATA%\WslPrivate\launchers`.
   - Confirm `notice.ps1` exists there; it may be a hidden file.
   - Confirm WSL helper commands exist in `/usr/local/bin`, especially `wechat-desktop`, `wechat-desktop-stop`, `winclip2wechat`, and `wechatclip2win`.
   - Confirm Windows file links exist in WSL, such as `~/Windows-C`, `~/Windows-Downloads`, and `~/Windows-Documents`, so Linux WeChat can send files directly from Windows disks and save received files back to Windows folders.
   - Run:
     `powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -Distro <DistroName>`

5. Start and verify.
   - Start the Windows clipboard widget:
     `wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-widget-hidden.vbs"`
   - Start Linux WeChat:
     `wsl -d <DistroName> -- wechat-desktop`
   - Ask me to scan the WeChat login QR code if needed.
   - Ask me to test typing Chinese in a Linux WeChat chat box. If Chinese input does not work, inspect `fcitx5`, `fcitx5-chinese-addons`, `fcitx5-pinyin`, and the environment variables exported by `wechat-desktop` before blaming WeChat.
   - Check status:
     `wsl -d <DistroName> -- wechat-desktop-status`
     `powershell -NoProfile -STA -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\WslPrivate\launchers\clipboard-watch.ps1" -Status`

6. Verify clipboard behavior.
   - Test Windows-to-Linux: copy text in Windows, use the widget's "同步到 WSL", then paste into Linux WeChat.
   - Test Linux-to-Windows: copy text inside Linux WeChat, wait briefly, then check whether Windows can paste it.
   - Test file transfer: in Linux WeChat, choose a file from `~/Windows-Downloads` or `~/Windows-Documents`, and test saving a received file back into one of those Windows-linked folders.
   - If automatic sync is not running, use the widget's listener status row or start:
     `wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-watch-hidden.vbs"`
   - Do not start a separate `wechatclip2win --watch`; this project uses one unified watcher.
   - Remember that automatic watcher syncs Windows image/file clipboard to Linux and Linux text clipboard to Windows. Windows text to Linux is intentionally done through the widget button or `winclip2wechat` to avoid clipboard loops.

7. Final report.
   - Tell me the distro name, where the repo was cloned, and whether WeChat, the bridge, the widget, and clipboard sync all work.
   - Give me only the daily commands I need:
     start WeChat, stop WeChat, open widget, check clipboard watcher status.
   - If anything could not be completed, explain the blocker and the exact next command or approval needed.
```

## Official Download Notes

The official Linux WeChat project site is:

```text
https://linux.weixin.qq.com/
```

The agent should fetch the current package from the official page at install time instead of relying on a hard-coded package URL.
