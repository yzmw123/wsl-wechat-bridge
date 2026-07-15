# Change Log

This file tracks repository changes made by agents. Keep entries short and append newest entries near the top.

## 2026-07-15

- Fixed P0-P2 hardening across privacy, process lifecycle, resource use, and diagnostics: logs now rotate, focus/notification logs avoid foreground titles and notification text, clipboard payloads use private temporary storage, normal stop no longer sends `SIGKILL`, notification daemon PIDs are included, PID-file stops validate command lines, and the unread badge watcher is opt-in with adaptive polling.
- Added runtime configuration/status for helper toggles, log rotation, clipboard TTL, and badge watcher polling; updated README, architecture docs, agent prompt, and WSL helper references to match.
- Deployed the refreshed helpers to `/usr/local/bin` and `%LOCALAPPDATA%\WslPrivate\launchers`, restarted only helper watchers/notification bridge, and stopped the old badge watcher without stopping WeChat.
- Recorded resolved local learning entries for the P0-P2 feature request and cross-shell verification pitfalls.
- Verification: PowerShell parser checks, Bash `bash -n` checks, Python compile checks, `git diff --check`, `scripts/install.ps1 -Distro Ubuntu-22.04`, `scripts/doctor.ps1 -Distro Ubuntu-22.04`, `wechat-desktop-status`, `wechat-desktop-stop --dry-run`, `wsl-app-notify-bridge --status`, and redacted `collect-status.ps1`.

- Added the standard local `.learnings` logs and recorded resolved tool-selection issues encountered during a read-only repository review.
- Verification: inspected the created Markdown files; no runtime tests needed for local process documentation.

- Made notification popups configurable and disabled them by default while preserving taskbar flashing; added the `消息弹窗` checkbox and local `settings.json` runtime setting.
- Added manual WSL-to-Windows clipboard sync from the widget, removed widget always-on-top behavior, and merged local helper path fallbacks back into source.
- Hardened `scripts/install.ps1` path conversion, file filtering, and Windows directory fallback so deployments from this workspace succeed.
- Updated README and WSL helper references for the new notification, clipboard, and troubleshooting behavior.
- Verification: ran PowerShell parser checks, Bash syntax checks, Python `py_compile`, `git diff --check`, deployed with `scripts/install.ps1 -NoDoctor`, verified installed helper hashes, and confirmed notification test logs `popup=False`, `flashed=1`, `popup=disabled`, `done`.

- Added `AGENTS.md` to define the repository rule that every agent-made file change needs a documentation record.
- Added this change log as the default place for future change records.
- Verification: inspected existing docs layout and git status; no runtime tests needed for documentation-only changes.
