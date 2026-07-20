# Change Log

This file tracks repository changes made by agents. Keep entries short and append newest entries near the top.

## 2026-07-20

- Repaired the local Sogou Pinyin 4.2.1 runtime by installing the Ubuntu Qt Quick/QML, gsettings-qt, OpenMP, and Xss libraries omitted from the package metadata; recorded the package post-install behavior and transient diagnostic failures in local learnings.
- Verification: no missing libraries from `sogoupinyin-service` or watchdog, clean package audit, running `fcitx`/Sogou service/watchdog, no prior loader or IPC errors in the current startup log, `fcitx_state=2`, and `nihao` conversion to UTF-8 `e4 bd a0 e5 a5 bd` (“你好”) in both an isolated GTK entry and WeChat's own search field on display `:20`.

## 2026-07-17

- Replaced the noisy default file-activity taskbar fallback with the numeric unread badge watcher: broad message/session storage writes are log-only again, while the badge watcher is enabled by default.
- Tightened badge classification to require light digit pixels inside the red component, so plain official-account, service-account, and muted-conversation dots do not trigger taskbar attention; added focused synthetic regression tests and updated user/agent documentation.
- Verification pending: Python unit tests and compile checks, Bash syntax checks, supplied screenshot analysis, install/hash checks, helper-only restart, runtime status/log checks, doctor, and `git diff --check`.

- Restored file-activity message fallback as taskbar-flash-only by default, so disabling the `消息弹窗` widget option no longer removes taskbar flashing for messages that do not emit D-Bus/X11 notification signals.
- Added a `notice.ps1` popup suppression switch for fallback notices, updated README/helper docs to document the separate popup and taskbar-flash behavior, and recorded the extensionless Python helper smoke-test loading gotcha in local learnings.
- Verification: PowerShell parser check for `notice.ps1`, Python `py_compile` for `wsl-app-notification-daemon`, `git diff --check`, `scripts/install.ps1 -Distro Ubuntu-22.04 -NoDoctor`, installed helper hash checks, `wsl-app-notify-bridge --test`, flash-only smoke test showing `suppress_popup=True` and `popup=suppressed`, `scripts/doctor.ps1 -Distro Ubuntu-22.04`, and status checks showing the bridge running while WeChat Desktop is currently stopped.

## 2026-07-15

- Replaced the README update-record link with a concise public-facing 2026-07-15 summary of the day's changes.
- Verification: `git diff --check`.

- Added a `README.md` update-record section linking to `docs/CHANGELOG.md` so users can find the full maintenance history from the project landing page.
- Verification: `git diff --check`.

- Fixed the nested Xephyr/openbox/tint2 desktop to a single workspace so mouse-wheel scrolling cannot move the user into unused `desktop2-4` workspaces; `wechat-restore` also enforces the single-workspace state.
- Moved the widget's `同步到 WSL` and `读取WSL剪切板` buttons onto one bottom row, and corrected README/helper docs to describe the new button placement and single-workspace desktop behavior.
- Deployed the updated Linux commands and Windows launcher files to `/usr/local/bin` and `%LOCALAPPDATA%\WslPrivate\launchers`, refreshed the current tint2 panel without stopping WeChat, and verified the desktop shortcut points at the updated private launcher.
- Updated the local learning record for recurring cross-shell verification quoting failures.
- Verification: Bash syntax checks for `wechat-desktop` and `wechat-restore`, PowerShell parser check for `clipboard-widget.ps1`, single-workspace runtime check with `wmctrl -d`, openbox/tint2 private config checks, `scripts/install.ps1 -Distro Ubuntu-22.04 -NoDoctor`, installed file hash checks, shortcut target inspection, `scripts/doctor.ps1 -Distro Ubuntu-22.04`, `wechat-desktop-status`, and `git diff --check`.

- Enlarged the `剪贴板` and `运行状态` tabs for readability, added a yellow/green status dot to the `运行状态` tab, and tied that dot to the unified clipboard watcher state.
- Updated README and helper docs to describe the tab status dot and clearer two-page widget layout.
- Verification: PowerShell parser check for `app/windows/clipboard-widget.ps1` and `git diff --check`.

- Updated the Windows clipboard widget to remove the `读取剪切板` and `同步并粘贴` buttons, rename the Linux-to-Windows action to `读取WSL剪切板`, and add a visible `运行状态` page for watcher status and recent output.
- Updated README, architecture, install prompt, and WSL helper reference docs to match the two-page widget layout and new button labels.
- Verification: PowerShell parser check for `app/windows/clipboard-widget.ps1`, `scripts/doctor.ps1 -Distro Ubuntu-22.04`, and `git diff --check`.

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
