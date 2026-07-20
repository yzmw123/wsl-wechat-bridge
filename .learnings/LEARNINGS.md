# Learnings

Corrections, insights, and knowledge gaps captured during development.

**Categories**: correction | insight | knowledge_gap | best_practice

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
