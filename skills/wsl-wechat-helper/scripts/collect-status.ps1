param(
    [string]$Distro = "Ubuntu-22.04"
)

$ErrorActionPreference = "Continue"

function Write-Section {
    param([string]$Title)
    ""
    "== $Title =="
}

function Invoke-Wsl {
    param([string[]]$CommandArgs)
    & wsl.exe -d $Distro -- @CommandArgs
}

function ConvertTo-RedactedLine {
    param([string]$Line)

    $redacted = $Line
    $redacted = $redacted -replace 'title=.*?(?=\sbody=|\spopup=|$)', 'title=<redacted>'
    $redacted = $redacted -replace 'body=.*?(?=\spopup=|$)', 'body=<redacted>'
    $redacted = $redacted -replace 'summary=.*$', 'summary=<redacted>'
    $redacted = $redacted -replace 'sample=.*$', 'sample=<redacted>'
    $redacted = $redacted -replace 'reason=title:[^ ]+:.*?(?=\shelper=|$)', 'reason=title:<redacted>'
    $redacted = $redacted -replace 'reason=dbus:.*?(?=\shelper=|$)', 'reason=dbus:<redacted>'
    $redacted = $redacted -replace 'reason=file-activity:.*?(?=\shelper=|$)', 'reason=file-activity:<redacted>'
    $redacted = $redacted -replace '(/[^\s]*/Pictures/WindowsClipboard/[^\s]+)', '<redacted-clipboard-path>'
    $redacted = $redacted -replace '(file:///[^\s]+)', '<redacted-file-uri>'
    return $redacted
}

function Invoke-WslRedacted {
    param([string[]]$CommandArgs)
    Invoke-Wsl -CommandArgs $CommandArgs | ForEach-Object { ConvertTo-RedactedLine -Line ([string]$_) }
}

function Get-RedactedContent {
    param(
        [string]$Path,
        [int]$Tail = 30
    )

    Get-Content -LiteralPath $Path -Tail $Tail | ForEach-Object { ConvertTo-RedactedLine -Line ([string]$_) }
}

$launcherDir = Join-Path $env:LOCALAPPDATA "WslPrivate\launchers"

Write-Section "Distro"
"distro=$Distro"

Write-Section "Installed WSL commands"
Invoke-Wsl -CommandArgs @("bash", "-lc", "command -v wechat-desktop wechat-desktop-status wechat-desktop-stop wechat-input-reset wechat-restore winclip2wechat wechatclip2win wsl-app-notify-bridge wsl-app-notify-bridge-restart wsl-app-notification-daemon wsl-app-badge-notify-watch wsl-app-focus-bridge wsl-focus-sink 2>/dev/null")

Write-Section "WeChat desktop status"
Invoke-Wsl -CommandArgs @("wechat-desktop-status")

Write-Section "Notification bridge status"
Invoke-Wsl -CommandArgs @("wsl-app-notify-bridge", "--status")

Write-Section "Notification bridge log"
Invoke-WslRedacted -CommandArgs @("bash", "-lc", "tail -n 30 ~/.cache/wechat-desktop/notice-bridge.log 2>/dev/null || true")

Write-Section "Notification daemon log"
Invoke-WslRedacted -CommandArgs @("bash", "-lc", "tail -n 30 ~/.cache/wechat-desktop/notification-daemon.log 2>/dev/null || true")

Write-Section "Focus watcher status"
$focusWatch = Join-Path $launcherDir "focus-watch.ps1"
if (Test-Path -LiteralPath $focusWatch) {
    $focusStatusOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $focusWatch -Status)
    if ($focusStatusOutput.Count -gt 0) {
        $focusStatusOutput
    }
    else {
        "focus_watch=status-empty"
    }
}
else {
    "missing=$focusWatch"
}

Write-Section "Focus watcher state"
$focusState = Join-Path $launcherDir "focus-watch.state"
if (Test-Path -LiteralPath $focusState) {
    Get-RedactedContent -Path $focusState -Tail 30
}
else {
    "missing=$focusState"
}

Write-Section "Focus bridge log"
Invoke-WslRedacted -CommandArgs @("bash", "-lc", "tail -n 30 ~/.cache/wechat-desktop/focus-bridge.log 2>/dev/null || true")

Write-Section "Windows launcher files"
if (Test-Path -LiteralPath $launcherDir) {
    Get-ChildItem -LiteralPath $launcherDir -Force |
        Sort-Object Name |
        Select-Object Name, Length, LastWriteTime
}
else {
    "missing=$launcherDir"
}

Write-Section "Windows notice log"
$noticeLog = Join-Path $launcherDir "notice.log"
if (Test-Path -LiteralPath $noticeLog) {
    Get-RedactedContent -Path $noticeLog -Tail 30
}
else {
    "missing=$noticeLog"
}

Write-Section "Unified clipboard watcher status"
$clipWatch = Join-Path $launcherDir "clipboard-watch.ps1"
if (Test-Path -LiteralPath $clipWatch) {
    $clipStatusOutput = @(& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $clipWatch -Status)
    if ($clipStatusOutput.Count -gt 0) {
        $clipStatusOutput
    }
    else {
        "clipboard_watch=status-empty"
    }
}
else {
    "missing=$clipWatch"
}

Write-Section "Clipboard widget status"
$widgetProcesses = @(Get-CimInstance Win32_Process | Where-Object {
        $_.CommandLine -and $_.CommandLine -match 'clipboard-widget\.ps1'
    })
if ($widgetProcesses.Count -gt 0) {
    foreach ($process in $widgetProcesses) {
        "clipboard_widget=running pid=$($process.ProcessId)"
    }
}
else {
    "clipboard_widget=stopped"
}

Write-Section "Unified clipboard watcher log"
$clipLog = Join-Path $launcherDir "clipboard-watch.log"
if (Test-Path -LiteralPath $clipLog) {
    Get-RedactedContent -Path $clipLog -Tail 30
}
else {
    "missing=$clipLog"
}

Write-Section "Legacy separate Linux clipboard watcher status"
Invoke-Wsl -CommandArgs @("wechatclip2win", "--status")

Write-Section "Linux clipboard manual sync log"
Invoke-WslRedacted -CommandArgs @("bash", "-lc", "tail -n 30 ~/.cache/wechat-desktop/wechatclip2win.log 2>/dev/null || true")

Write-Section "Focus watcher log"
$focusLog = Join-Path $launcherDir "focus-watch.log"
if (Test-Path -LiteralPath $focusLog) {
    Get-RedactedContent -Path $focusLog -Tail 30
}
else {
    "missing=$focusLog"
}

Write-Section "Windows Start apps containing WeChat"
Get-StartApps | Where-Object {
    $_.Name -match "(?i)wechat|weixin|微信" -or $_.AppID -match "(?i)wechat|weixin|微信"
}
