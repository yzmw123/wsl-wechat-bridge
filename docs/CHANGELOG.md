# Change Log

This file tracks repository changes made by agents. Keep entries short and append newest entries near the top.

## 2026-07-15

- Made notification popups configurable and disabled them by default while preserving taskbar flashing; added the `消息弹窗` checkbox and local `settings.json` runtime setting.
- Added manual WSL-to-Windows clipboard sync from the widget, removed widget always-on-top behavior, and merged local helper path fallbacks back into source.
- Hardened `scripts/install.ps1` path conversion, file filtering, and Windows directory fallback so deployments from this workspace succeed.
- Updated README and WSL helper references for the new notification, clipboard, and troubleshooting behavior.
- Verification: ran PowerShell parser checks, Bash syntax checks, Python `py_compile`, `git diff --check`, deployed with `scripts/install.ps1 -NoDoctor`, verified installed helper hashes, and confirmed notification test logs `popup=False`, `flashed=1`, `popup=disabled`, `done`.

- Added `AGENTS.md` to define the repository rule that every agent-made file change needs a documentation record.
- Added this change log as the default place for future change records.
- Verification: inspected existing docs layout and git status; no runtime tests needed for documentation-only changes.
