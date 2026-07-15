param(
    [string]$Distro = "Ubuntu-22.04",
    [int]$PollMs = 350,
    [int]$EnforceMs = 2500,
    [switch]$Status,
    [switch]$Once
)

$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ScriptDir "focus-watch.log"
$PidFile = Join-Path $ScriptDir "focus-watch.pid"
$StateFile = Join-Path $ScriptDir "focus-watch.state"

function Get-PositiveIntSetting {
    param(
        [string]$Name,
        [int]$Default
    )

    try {
        $raw = [Environment]::GetEnvironmentVariable($Name)
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $Default
        }

        $value = [int64]$raw
        if ($value -gt 0 -and $value -le [int64][int]::MaxValue) {
            return [int]$value
        }
    }
    catch {}

    return $Default
}

$LogMaxBytes = Get-PositiveIntSetting -Name "WSL_WECHAT_LOG_MAX_BYTES" -Default 5242880
$LogBackups = Get-PositiveIntSetting -Name "WSL_WECHAT_LOG_BACKUPS" -Default 2

function Rotate-LogFile {
    param([string]$Path)

    try {
        if ($LogMaxBytes -le 0 -or $LogBackups -le 0) {
            return
        }
        if (-not (Test-Path -LiteralPath $Path)) {
            return
        }
        $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
        if ($null -eq $item -or $item.Length -lt $LogMaxBytes) {
            return
        }

        for ($i = $LogBackups - 1; $i -ge 1; $i--) {
            $src = "$Path.$i"
            $dst = "$Path.$($i + 1)"
            if (Test-Path -LiteralPath $src) {
                Move-Item -LiteralPath $src -Destination $dst -Force -ErrorAction SilentlyContinue
            }
        }
        Move-Item -LiteralPath $Path -Destination "$Path.1" -Force -ErrorAction SilentlyContinue
    }
    catch {}
}

function Write-FocusLog {
    param([string]$Message)
    try {
        Rotate-LogFile -Path $LogFile
        "$(Get-Date -Format o) $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
    catch {}
}

if ($Status) {
    if (Test-Path -LiteralPath $PidFile) {
        $watchPid = Get-Content -LiteralPath $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1
        $process = $null
        if ($watchPid -match '^\d+$') {
            $process = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $watchPid) -ErrorAction SilentlyContinue
        }
        if ($process -and $process.CommandLine -match 'focus-watch\.ps1') {
            "focus_watch=running pid=$watchPid"
            exit 0
        }
    }
    "focus_watch=stopped"
    exit 0
}

$Win32Type = @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class WslFocusWatchWin32 {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
}
"@

Add-Type -TypeDefinition $Win32Type

function Get-ForegroundTitle {
    $buffer = New-Object System.Text.StringBuilder 512
    [void][WslFocusWatchWin32]::GetWindowText([WslFocusWatchWin32]::GetForegroundWindow(), $buffer, $buffer.Capacity)
    $buffer.ToString()
}

function Test-WeChatDesktopTitle {
    param([string]$Title)
    if ([string]::IsNullOrWhiteSpace($Title)) {
        return $false
    }
    return ($Title.IndexOf("WeChat Desktop", [StringComparison]::OrdinalIgnoreCase) -ge 0)
}

function Write-FocusState {
    param([bool]$Active)

    $label = if ($Active) { "active" } else { "inactive" }
    $tmpFile = "$StateFile.tmp"
    try {
        @(
            "timestamp=$(Get-Date -Format o)"
            "state=$label"
        ) | Out-File -FilePath $tmpFile -Encoding UTF8
        Move-Item -LiteralPath $tmpFile -Destination $StateFile -Force
    }
    catch {
        Write-FocusLog "state_write_error=$($_.Exception.Message)"
    }
}

function Send-FocusState {
    param(
        [bool]$Active,
        [string]$Title,
        [string]$Reason = "change",
        [switch]$Quiet
    )

    $mode = if ($Active) { "--wechat-active" } else { "--wechat-inactive" }
    $label = if ($Active) { "active" } else { "inactive" }
    if (-not $Quiet) {
        Write-FocusLog "windows_foreground=$label reason=$Reason"
    }

    try {
        & wsl.exe -d $Distro -- wsl-app-focus-bridge $mode | Out-Null
    }
    catch {
        Write-FocusLog "wsl_error=$($_.Exception.Message)"
    }
}

try {
    "$PID" | Out-File -FilePath $PidFile -Encoding ASCII
}
catch {}

Write-FocusLog "started pid=$PID distro=$Distro poll_ms=$PollMs enforce_ms=$EnforceMs"

$lastState = $null
$lastEnforceAt = [datetime]::MinValue
$lastStateWriteAt = [datetime]::MinValue

while ($true) {
    $title = Get-ForegroundTitle
    $active = Test-WeChatDesktopTitle -Title $title
    $now = Get-Date
    $writeState = $false

    if ($null -eq $lastState -or $active -ne $lastState) {
        Send-FocusState -Active $active -Title $title -Reason "change"
        $lastState = $active
        $lastEnforceAt = $now
        $writeState = $true
    }
    elseif (-not $active -and $EnforceMs -gt 0 -and (($now - $lastEnforceAt).TotalMilliseconds -ge $EnforceMs)) {
        Send-FocusState -Active $active -Title $title -Reason "enforce" -Quiet
        $lastEnforceAt = $now
        $writeState = $true
    }
    elseif (($now - $lastStateWriteAt).TotalMilliseconds -ge ([Math]::Max(1000, $EnforceMs))) {
        $writeState = $true
    }

    if ($writeState) {
        Write-FocusState -Active $active
        $lastStateWriteAt = $now
    }

    if ($Once) {
        break
    }

    Start-Sleep -Milliseconds ([Math]::Max(150, $PollMs))
}
