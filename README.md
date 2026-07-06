# WSL WeChat Bridge

在 Windows + WSL2 里更舒服地使用 Linux 微信。

这个项目提供一套本地桥接工具：把 Linux 微信运行在一个独立的嵌套桌面里，同时提供 Windows 桌面小组件、剪切板同步、启动/关闭控制，以及可选的通知和焦点辅助能力。

本项目不包含、也不分发微信安装包。Linux 微信请从官方页面获取：

```text
https://linux.weixin.qq.com/
```

## 适合谁

- 你想在 Windows 上使用 WSL 里的 Linux 微信。
- 你不想让 Windows 开始菜单/搜索里出现一堆 WeChat/微信入口。
- 你希望 Windows 和 Linux 微信之间复制粘贴更顺手。
- 你希望有一个小窗口可以手动把文字、图片、文件同步到 WSL 剪切板。
- 你希望后续可以让 AI agent 帮你检查、修复这套本地环境。

## 主要功能

Windows 桌面小组件可以：

- 读取并预览 Windows 剪切板里的文字、图片、文件；
- 一键同步到 WSL/Linux 剪切板；
- 一键启动 Linux 微信；
- 一键关闭卡住的 Linux 微信进程；
- 显示统一剪切板监听状态；
- 在监听异常时一键启动，在监听正常时一键停止。

统一剪切板监听负责：

- Windows 图片/文件剪切板同步到 Linux 微信；
- Linux/X11 文本剪切板同步回 Windows。

项目刻意只使用一个统一监听，不再额外启动单独的 `wechatclip2win --watch`，避免循环同步和互相抢剪切板。

## Agent 一键安装

如果你使用 Codex、Claude Code、Cursor Agent 之类的本地 agent，可以把下面这段话复制给它。发布到 GitHub 后，把 `<REPO_URL>` 替换成你的仓库地址。

```text
请从 <REPO_URL> 在我的 Windows 电脑上安装 WSL WeChat Bridge。

先检查我的 WSL2 和可用的 Ubuntu 发行版是否已经安装。如果 WSL 没装，或者需要启用 Windows 功能、重启、管理员权限，请先说明需要做什么并征求我的确认。若 WSL 已可用，请安装或复用 Ubuntu-22.04 或其他 Ubuntu 发行版，从 https://linux.weixin.qq.com/ 下载并安装最新的官方 Linux 微信，然后安装这个 bridge 项目。

安装完成后，通过 bridge 启动 Linux 微信，打开 Windows 剪切板小组件，验证 Windows 到 WSL 的剪切板同步，以及 Linux 微信到 Windows 的文本同步，最后只把日常常用命令告诉我。不要使用非官方微信安装包，除非我明确同意。
```

完整 agent 安装提示词见：[docs/AGENT_INSTALL_PROMPT.md](docs/AGENT_INSTALL_PROMPT.md)

## 手动安装

前提：

- Windows 11；
- 已安装 WSL2；
- 有一个 Ubuntu 发行版，例如 `Ubuntu-22.04`；
- Linux 微信已经安装在该 WSL 发行版中；
- WSL 里具备必要依赖，例如 `xclip`、`wmctrl`、`xdotool`、`xserver-xephyr`、`openbox`、`tint2`、`dbus-x11`、`fcitx5`、`python3-dbus`、`python3-gi`。

安装项目：

```powershell
cd path\to\wsl-wechat-bridge
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Distro Ubuntu-22.04
```

安装脚本会把 Windows 辅助文件复制到：

```powershell
%LOCALAPPDATA%\WslPrivate\launchers
```

并把 WSL 侧命令安装到：

```text
/usr/local/bin
```

默认还会创建桌面快捷方式：

```text
WSL剪切板同步.lnk
```

## 日常命令

启动 Linux 微信：

```powershell
wsl -d Ubuntu-22.04 -- wechat-desktop
```

查看状态：

```powershell
wsl -d Ubuntu-22.04 -- wechat-desktop-status
```

正常关闭：

```powershell
wsl -d Ubuntu-22.04 -- wechat-desktop-stop
```

强制关闭：

```powershell
wsl -d Ubuntu-22.04 -- wechat-desktop-stop --force
```

打开桌面小组件：

```powershell
wscript.exe //B "$env:LOCALAPPDATA\WslPrivate\launchers\start-clipboard-widget-hidden.vbs"
```

查看统一剪切板监听状态：

```powershell
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\WslPrivate\launchers\clipboard-watch.ps1" -Status
```

## 目录结构

```text
app/
  linux/bin/        安装到 WSL /usr/local/bin 的命令
  windows/          WinForms 小组件、监听脚本、图标、Windows 辅助脚本
  windows/launchers 隐藏启动用的 VBS/CMD 入口
docs/               文档
scripts/install.ps1 安装脚本
skills/             可选 Codex 维护 skill
```

## 小组件和 Skill 的关系

普通用户只需要小组件和安装脚本，不需要 skill。

`skills/wsl-wechat-helper` 是给 Codex 或其他维护 agent 用的“维修手册”。它记录了本地架构、排障命令、已知坑和安全规则。保留它的好处是：后续如果某台机器剪切板、通知、焦点桥坏了，agent 能更快定位问题。

简单说：

- 小组件：给人用。
- skill：给 agent 维修用。

## 隐私说明

本项目的日志只应记录运行状态，例如进程号、字节数、hash、启动状态等；不应主动记录剪切板正文或微信消息正文。

使用前仍建议你自行审阅代码，尤其是在处理敏感账号或敏感文件时。
