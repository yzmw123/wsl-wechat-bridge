# Feature Requests

Capabilities requested by the user.

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
