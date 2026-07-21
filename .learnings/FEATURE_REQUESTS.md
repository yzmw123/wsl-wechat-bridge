# Feature Requests

Capabilities requested by the user.

---

## [FEAT-20260721-002] public-input-reset-hardening

**Logged**: 2026-07-21T16:20:00+08:00
**Priority**: high
**Status**: resolved
**Area**: infra

### Requested Capability
Harden the new Sogou reset control so the repository can be published with accurate compatibility claims and safer behavior on other installations.

### User Context
The current reset works on the local Ubuntu 22.04, fcitx4, Sogou 4.x setup, but the user wants other GitHub users to get predictable behavior without misleading generic input-method support or broad process termination.

### Complexity Estimate
complex

### Suggested Implementation
Add capability detection, explicit Sogou/fcitx4 labeling, persistent distro selection, display-scoped process matching, a reset lock, restart confirmation, compatibility documentation, and automated safety tests.

### Metadata
- Frequency: first_time
- Related Features: wechat-input-reset, clipboard-widget, installer, doctor

### Resolution
- **Resolved**: 2026-07-21T16:50:00+08:00
- **Notes**: Added an explicit Sogou/fcitx4 capability contract, persistent distro selection, display-scoped process handling, reset locking and confirmation, unsupported-environment button disabling, structured result reporting, compatibility documentation, and automated safety tests. Deployed locally and verified without restarting the active WeChat session.

---

## [FEAT-20260715-001] p0-p2-hardening-and-helper-features

**Logged**: 2026-07-15T11:30:00+08:00
**Priority**: high
**Status**: resolved
**Area**: infra

### Requested Capability
Fix all identified P0-P2 issues and add the worthwhile helper features from the repository review.

### User Context
The local WSL WeChat bridge needed privacy hardening, safer stop behavior, lower default resource use, bounded logs, clearer status/config, and updated docs.

### Complexity Estimate
complex

### Suggested Implementation
Implement log rotation, privacy-safe logging, private clipboard temp storage, PID validation, graceful stop semantics, opt-in adaptive badge watcher, runtime status/config keys, and synchronized documentation.

### Metadata
- Frequency: first_time
- Related Features: notification_bridge, focus_bridge, clipboard_bridge, badge_watch

### Resolution
- **Resolved**: 2026-07-15T11:30:00+08:00
- **Notes**: Implemented, deployed locally, restarted helper watchers/notification bridge, stopped the old badge watcher, and verified with syntax checks, doctor, status, dry-run, and redacted status collection.

---
