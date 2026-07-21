# Learnings

Corrections, insights, and knowledge gaps captured during development.

**Categories**: correction | insight | knowledge_gap | best_practice

---

## [LRN-20260721-002] correction

**Logged**: 2026-07-21T17:21:27+08:00
**Priority**: critical
**Status**: promoted
**Area**: docs

### Summary
Every public push must update the README's user-facing update record and explicitly audit the full outgoing change set for secrets.

### Details
The 2026-07-21 implementation was recorded in `docs/CHANGELOG.md` but the README update section still ended at 2026-07-15. Because this is a public repository, checking only code correctness or the latest diff is insufficient: all commits ahead of the remote and their documentation must be reviewed for credentials and private data before push.

### Suggested Action
Treat README update history, detailed changelog coverage, outgoing-commit scope review, secret scanning, and relevant verification as mandatory pre-push gates.

### Metadata
- Source: user_feedback
- Related Files: README.md, docs/CHANGELOG.md, AGENTS.md
- Tags: public-repository, release-process, changelog, secret-scanning
- Promoted: AGENTS.md

### Resolution
- **Resolved**: 2026-07-21T17:21:27+08:00
- **Notes**: Added the missing README entry and promoted mandatory public-release and sensitive-information review rules to `AGENTS.md`.

---

## [LRN-20260721-001] correction

**Logged**: 2026-07-21T13:40:04+08:00
**Priority**: high
**Status**: resolved
**Area**: config

### Summary
The initial Sogou repair restored conversion correctness but did not verify sustained input latency in normal WSL use.

### Details
The previous check proved that `nihao` could convert to “你好” in an isolated entry and WeChat search field. The user later reported that switching to Sogou makes ordinary WSL typing severely delayed even though English input remains responsive, so process startup and one successful conversion were insufficient acceptance criteria.

### Suggested Action
Profile Sogou/fcitx CPU, I/O, D-Bus, network, and per-keystroke latency under the real nested X session; require repeated conversions with bounded latency before marking the repair complete.

### Metadata
- Source: user_feedback
- Related Files: app/linux/bin/wechat-desktop
- Tags: wsl, sogoupinyin, fcitx4, latency, regression
- See Also: LRN-20260720-001

### Resolution
- **Resolved**: 2026-07-21T14:03:33+08:00
- **Notes**: Found `/dev/mqueue` unmounted and nine stale Sogou queues, including a fixed queue with pending data. Added scoped auto-mount, stale-queue cleanup, managed fcitx shutdown, status reporting, and matching installer/doctor/docs updates. Verified 20 consecutive conversions (0 failures, 120–150 ms after a 766 ms cold round), 10 after restart (0 failures, 126–144 ms after a 382 ms cold round), and 5 after explicitly unmounting `/dev/mqueue` (0 failures, 125–136 ms after a 508 ms cold round); queue backlog remained zero.

---

## [LRN-20260720-001] insight

**Logged**: 2026-07-20T17:01:42+08:00
**Priority**: high
**Status**: resolved
**Area**: config

### Summary
Sogou Pinyin 4.2.1 on Ubuntu can install cleanly while remaining unusable because its post-install script hides bundled Qt libraries without declaring all replacement system libraries.

### Details
On Ubuntu, the package moves `/opt/sogoupinyin/files/lib/qt5` to `qt5.bak` and renames `qt.conf`, expecting system Qt. Its declared dependencies did not install Qt Quick/QML, gsettings-qt, OpenMP, or Xss on this minimal WSL image. `fcitx` loaded the Sogou addon, but `sogoupinyin-service` and its watchdog failed to start, leaving only English input.

### Suggested Action
When this package logs missing shared libraries, check it with `ldd` and install `libqt5quickwidgets5`, `libqt5quick5`, `libqt5qml5`, `libgsettings-qt1`, `libgomp1`, and `libxss1`. Then restart the `fcitx` session and verify a real conversion through the target X display.

### Metadata
- Source: error
- Related Files: /opt/sogoupinyin/files/bin/sogoupinyin-service, /etc/X11/Xsession.d/72sogoupinyinsogouimebs
- Tags: wsl, sogoupinyin, fcitx4, qt5, shared-libraries

### Resolution
- **Resolved**: 2026-07-20T17:01:42+08:00
- **Notes**: Installed the seven required Ubuntu packages (including the transitive `libqt5qmlmodels5`), restarted the nested desktop, and converted `nihao` to UTF-8 `e4 bd a0 e5 a5 bd` (“你好”) with `fcitx_state=2` in both an isolated GTK entry and WeChat's own search field.

---
