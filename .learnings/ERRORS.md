# Errors

Command failures and integration errors.

---

## [ERR-20260721-006] start-process-wsl-exit-code-unavailable

**Logged**: 2026-07-21T16:43:00+08:00
**Priority**: high
**Status**: resolved
**Area**: frontend

### Summary
Windows PowerShell returned an empty `ExitCode` for a completed redirected `wsl.exe` capability process, causing a valid Sogou reset capability result to be marked unsupported.

### Error
```
input_reset_capability=unsupported ... reason=input_method=sogoupinyin
```

### Context
- `wechat-input-reset --check` wrote the complete successful contract: `status=supported`, `framework=fcitx4`, and `input_method=sogoupinyin`.
- The widget had required both the structured success line and `$process.ExitCode -eq 0`.
- On the installed Windows PowerShell 5 runtime, the redirected `Start-Process -PassThru` object exposed a blank exit code even after `WaitForExit()`.

### Suggested Fix
Use the helper's unique structured terminal status as the authoritative result, and treat the process exit code as optional diagnostic metadata.

### Metadata
- Reproducible: yes
- Related Files: app/windows/clipboard-widget.ps1, app/linux/bin/wechat-input-reset

### Resolution
- **Resolved**: 2026-07-21T16:44:00+08:00
- **Notes**: Capability now trusts `status=supported`; reset success trusts `status=ok`; missing exit codes are logged as `unavailable`, and failures surface the helper's `error=` reason.

---

## [ERR-20260721-005] powershell-expanded-bash-loop-variable

**Logged**: 2026-07-21T16:20:00+08:00
**Priority**: low
**Status**: resolved
**Area**: tests

### Summary
A read-only WSL process probe lost its Bash loop variable while crossing PowerShell and `bash -lc`.

### Error
```
/proc//environ: No such file or directory
```

### Context
- The probe embedded Bash `$p` references in a PowerShell command string.
- PowerShell removed the variable before Bash evaluated the loop, so the probe returned no process environment data.
- No process was changed or stopped.
- A later source search repeated the same class of issue with a `$script:` regex; `Select-String -SimpleMatch` avoided interpolation.
- A separate inline debug command that created fixed-name temporary files was rejected by the shell policy; runtime code continues to use unique temporary paths and normal cleanup.

### Suggested Fix
Avoid cross-shell variables for process probes; pass fixed PIDs as direct WSL arguments or encode the Bash script before invocation.

### Metadata
- Reproducible: yes
- Related Files: app/linux/bin/wechat-desktop-stop, app/linux/bin/wechat-input-reset
- See Also: ERR-20260715-003

### Resolution
- **Resolved**: 2026-07-21T16:20:00+08:00
- **Notes**: Continued with fixed-PID/direct-argument probes, literal PowerShell searches, and repository/runtime tests that do not depend on policy-blocked inline temp-file debugging.

---

## [ERR-20260721-003] input-reset-required-active-context

**Logged**: 2026-07-21T14:14:32+08:00
**Priority**: medium
**Status**: resolved
**Area**: config

### Summary
The first `wechat-input-reset` design replaced fcitx while WeChat still held the old input context; later attempts to preserve fcitx left the proprietary Sogou addon attached to unlinked message queues.

### Error
```
status=error
error=fcitx is not active after selecting Sogou
```

### Context
- Replacing fcitx without restarting WeChat left the running client connected to the old input-method process and reporting state 0.
- Restarting only `sogoupinyin-service` while preserving fcitx recreated one queue, but the addon retained the deleted queue handle and could not convert text.
- Resuming Sogou's watchdog after killing the service caused it to execute `fcitx -r`, replacing fcitx behind WeChat anyway.
- The Windows widget remains foreground during reset, so the new session legitimately reports state 0 until a Linux input context is focused.

### Suggested Fix
Use the managed desktop stop path to close WeChat/fcitx/Sogou together, clean only current-uid/current-display queues, wait until the old X display is stably unavailable, relaunch through a detached Windows process, and arm activation for the first Linux input context.

### Metadata
- Reproducible: yes
- Related Files: app/linux/bin/wechat-input-reset
- See Also: LRN-20260721-001

### Resolution
- **Resolved**: 2026-07-21T15:07:00+08:00
- **Notes**: Implemented a controlled nested-desktop restart. Verified new WeChat/fcitx PIDs, two rebuilt queues, automatic state 2 on the first WeChat search focus, and `nihao` conversion to “你好”.

---

## [ERR-20260721-004] input-reset-relaunch-race

**Logged**: 2026-07-21T15:02:00+08:00
**Priority**: medium
**Status**: resolved
**Area**: config

### Summary
The first controlled reset relaunch reused the old nested X display during its shutdown window and then exited.

### Error
```
status=error
error=WeChat did not restart
```

### Context
- `wechat-desktop-stop` had returned, but `xdpyinfo :20` briefly still succeeded.
- The new launcher skipped Xephyr creation, connected helpers to the dying display, and lost them when that display closed.
- The generated VBS launcher was unreliable in this nested recovery path; a detached Windows `Start-Process wsl.exe` launch worked.
- An optional `shellcheck` verification was unavailable in the distro, so Bash validation used `bash -n` plus live integration instead.

### Resolution
- **Resolved**: 2026-07-21T15:06:00+08:00
- **Notes**: Required five consecutive failed display probes before relaunch and used Windows PowerShell `Start-Process`. The next reset rebuilt WeChat, fcitx, Sogou, and both queues successfully.

---

## [ERR-20260721-001] powershell-wsl-verification-wrappers

**Logged**: 2026-07-21T14:03:33+08:00
**Priority**: low
**Status**: resolved
**Area**: tests

### Summary
Several diagnostic wrappers failed because PowerShell collection semantics and cross-shell path/variable expansion were handled incorrectly.

### Error
```
Argument types do not match
Variable reference is not valid. ':' was not followed by a valid variable name character.
You cannot call a method on a null-valued expression.
The term 'id' is not recognized as a name of a cmdlet.
```

### Context
- A generic line-range printer passed loosely typed array values to `[Math]::Min`.
- A parser-check message used `$file:` instead of `${file}:`.
- A status wrapper applied `-notmatch` to an array instead of testing for an exact line.
- A Windows path and `$(id -u)` crossed PowerShell/WSL/Bash quoting layers without isolation.
- One failed screenshot path produced a temporary untracked screenshot in the repository; it was removed after verifying its resolved path was inside the workspace.
- A final syntax wrapper sent every extensionless Linux helper to `bash -n`, including two Python programs, instead of selecting files by shebang.

### Suggested Fix
Use simple per-file checks, exact collection membership (`-contains`), known `/mnt/<drive>/...` paths, and base64-encoded Bash scripts when non-trivial commands must cross PowerShell and WSL.

### Metadata
- Reproducible: yes
- Related Files: none
- Recurrence-Count: 6
- See Also: ERR-20260715-002, ERR-20260715-003

### Resolution
- **Resolved**: 2026-07-21T14:03:33+08:00
- **Notes**: Retried with corrected PowerShell syntax, encoded Bash scripts, and shebang-based script classification; the subsequent syntax, runtime, latency, and cleanup checks completed successfully.

---

## [ERR-20260721-002] doctor-required-unused-fallback-engine

**Logged**: 2026-07-21T14:03:33+08:00
**Priority**: low
**Status**: resolved
**Area**: config

### Summary
The first updated doctor run incorrectly required `fcitx-pinyin` even when the installed and verified Chinese engine was Sogou Pinyin.

### Error
```
[fail] linux package missing: fcitx-pinyin
[warn] doctor result - 1 issue(s) found.
```

### Context
- `fcitx-pinyin` is a useful default fallback for new installs but is not required for a working Sogou Pinyin session.
- All Sogou runtime libraries, `/dev/mqueue`, fcitx, and repeated conversion checks were healthy.

### Suggested Fix
Require `fcitx-pinyin` only when Sogou is absent; report it as informational when Sogou is installed.

### Metadata
- Reproducible: yes
- Related Files: scripts/doctor.ps1

### Resolution
- **Resolved**: 2026-07-21T14:03:33+08:00
- **Notes**: Made the fallback check conditional and reran the doctor successfully with no issues.

---

## [ERR-20260720-001] collect-status-timeout

**Logged**: 2026-07-20T16:48:04+08:00
**Priority**: low
**Status**: resolved
**Area**: config

### Summary
The WSL WeChat status collector did not finish within the initial 30-second command timeout.

### Error
```
command timed out after 34137 milliseconds
```

### Context
- Ran the read-only `collect-status.ps1` helper before diagnosing a WSL input-method failure.
- The Ubuntu-22.04 distribution was running, so the slow probe will be isolated or retried with a larger timeout.

### Suggested Fix
Retry with a larger timeout and split out individual WSL probes if the collector still hangs.

### Metadata
- Reproducible: unknown
- Related Files: C:\Users\Administrator\.codex\skills\wsl-wechat-helper\scripts\collect-status.ps1

### Resolution
- **Resolved**: 2026-07-20T16:49:03+08:00
- **Notes**: The retry completed in about 10 seconds; the initial timeout was transient.

---

## [ERR-20260720-002] nested-zenity-window-not-found

**Logged**: 2026-07-20T16:57:00+08:00
**Priority**: low
**Status**: resolved
**Area**: tests

### Summary
The first end-to-end Sogou test could not find its temporary Zenity input window on nested display `:20`.

### Error
```
You cannot call a method on a null-valued expression.
```

### Context
- Zenity was started with `DISPLAY=:20`, but inherited WSLg Wayland environment variables.
- The test searched only the nested X11 display and received no window ID.
- The focus watcher was restored in the PowerShell `finally` block.

### Suggested Fix
Retry with `GDK_BACKEND=x11` and an empty `WAYLAND_DISPLAY`, and validate that Zenity is installed and visible before interacting with it.

### Metadata
- Reproducible: unknown
- Related Files: none

### Resolution
- **Resolved**: 2026-07-20T17:01:00+08:00
- **Notes**: Forced GTK onto X11, treated the single `xdotool` result as a full numeric ID instead of indexing its first character, and completed the isolated input test successfully.

---

## [ERR-20260720-003] powershell-rg-glob

**Logged**: 2026-07-20T17:15:00+08:00
**Priority**: low
**Status**: resolved
**Area**: tests

### Summary
A repository secret scan passed a Bash-style `tmp-*.sh` path directly to `rg` under PowerShell.

### Error
```
rg: tmp-*.sh: The filename, directory name, or volume label syntax is incorrect. (os error 123)
```

### Context
- The scan covered tracked source directories and top-level temporary shell scripts before an all-files commit.
- PowerShell did not expand the wildcard into file paths acceptable to this `rg` invocation.

### Suggested Fix
Use `rg --glob 'tmp-*.sh'` from the repository root instead of passing the wildcard as a path.

### Metadata
- Reproducible: yes
- Related Files: none
- See Also: ERR-20260715-003

### Resolution
- **Resolved**: 2026-07-20T17:15:00+08:00
- **Notes**: Retried the scan with `rg` glob filtering.

---

## [ERR-20260715-001] review-tool-selection

**Logged**: 2026-07-15T10:10:27+08:00
**Priority**: low
**Status**: resolved
**Area**: config

### Summary
The repository review used a Plan-mode input control in Default mode and then hit a PowerShell pipeline parsing error while checking optional paths.

### Error
```
request_user_input is unavailable in Default mode
An empty pipe element is not allowed.
```

### Context
- Attempted a non-blocking priority question during a read-only repository review.
- Attempted to pipe the output of a PowerShell `foreach` statement without grouping it.
- No runtime or repository content was affected by either failed operation.

### Suggested Fix
Ask optional questions in commentary only when needed in Default mode, and use simple existence checks or wrap PowerShell statement output before piping.

### Metadata
- Reproducible: yes
- Related Files: none
- Recurrence-Count: 2

### Resolution
- **Resolved**: 2026-07-15T10:10:27+08:00
- **Notes**: Continued with the default review priorities and simpler read-only commands.

---

## [ERR-20260715-002] wsl-bash-check-quoting

**Logged**: 2026-07-15T10:20:00+08:00
**Priority**: low
**Status**: resolved
**Area**: tests

### Summary
A bulk Bash syntax-check command lost shell variables while crossing JavaScript, PowerShell, WSL, and Bash quoting layers.

### Error
```
syntax error: unexpected end of file
```

### Context
- Attempted to iterate over repository scripts inside one nested `bash -lc` command.
- The failure was in the verification wrapper, not in a repository script.

### Suggested Fix
Enumerate files in PowerShell and invoke `wsl.exe --exec bash -n` once per file to avoid nested shell interpolation.

### Metadata
- Reproducible: yes
- Related Files: app/linux/bin

### Resolution
- **Resolved**: 2026-07-15T10:21:00+08:00
- **Notes**: The per-file syntax check completed successfully.

---

## [ERR-20260715-003] cross-shell-verification-quoting

**Logged**: 2026-07-15T11:30:00+08:00
**Priority**: medium
**Status**: resolved
**Area**: tests

### Summary
Several verification commands failed because PowerShell, WSL, Bash, and mixed script-type checks need stricter quoting and file selection.

### Error
```
Variable reference is not valid: $file:
invalid indirect expansion
bash -n failed on Python scripts
quoted one-line Bash stop command expanded variables incorrectly
```

### Context
- PowerShell strings containing `$file:` need `${file}`.
- Bash indirect env lookup should use `printenv "$key"` rather than `${!key-}`.
- Bulk `bash -n` checks must skip Python scripts by shebang.
- For state-changing WSL helper operations, `wsl --exec python3 -c ...` avoided fragile PowerShell-to-Bash quoting.

### Suggested Fix
Use parser-safe PowerShell interpolation, select files by shebang before syntax checks, prefer `printenv` for dynamic env keys, and avoid dense cross-shell one-liners for PID operations.

### Metadata
- Reproducible: yes
- Related Files: app/linux/bin/wechat-desktop, app/linux/bin/wechat-desktop-status
- See Also: ERR-20260715-002
- Recurrence-Count: 7
- Last-Seen: 2026-07-20T17:20:00+08:00

### Resolution
- **Resolved**: 2026-07-15T11:30:00+08:00
- **Notes**: Corrected the code and reran PowerShell parser, Bash syntax, Python compile, and runtime checks successfully. On later helper changes, dense `wsl bash -lc` one-liners failed again. Escaped quotes around Bash `$HOME` once produced a root-level log path, later probes let PowerShell expand Bash/dpkg variables before WSL, and a later bulk `bash -n` list again included an extensionless Python helper. Retries should select interpreters by shebang, use fixed paths/PIDs, default command formats, direct executable arguments, or encoded scripts with no cross-shell variable interpolation.

---

## [ERR-20260717-001] importlib-load-extensionless-script

**Logged**: 2026-07-17T10:52:00+08:00
**Priority**: low
**Status**: resolved
**Area**: tests

### Summary
`importlib.util.spec_from_file_location` returned no loader for the extensionless installed Python helper script.

### Error
```
AttributeError: 'NoneType' object has no attribute 'loader'
```

### Context
- Attempted to load `/usr/local/bin/wsl-app-notification-daemon` from a WSL Python smoke test.
- The installed helper has no `.py` suffix, so Python could not infer a source loader from the file name.

### Suggested Fix
Use `importlib.machinery.SourceFileLoader` when smoke-testing extensionless Python helper scripts.

### Metadata
- Reproducible: yes
- Related Files: app/linux/bin/wsl-app-notification-daemon

### Resolution
- **Resolved**: 2026-07-17T10:52:00+08:00
- **Notes**: Switched the smoke test to an explicit source loader.

---
