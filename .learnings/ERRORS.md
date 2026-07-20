# Errors

Command failures and integration errors.

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
