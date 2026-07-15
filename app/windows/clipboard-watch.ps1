param(
    [string]$Distro = "Ubuntu-22.04",
    [int]$PollMs = 350,
    [int]$LinuxPollMs = 850,
    [switch]$Status
)

$ErrorActionPreference = "Continue"

Add-Type -AssemblyName System.Windows.Forms

Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
public static class WinClipboardNative {
    [DllImport("user32.dll")]
    public static extern uint GetClipboardSequenceNumber();
}
"@

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $scriptDir "clipboard-watch.pid"
$logFile = Join-Path $scriptDir "clipboard-watch.log"

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

function Write-ClipLog {
    param([string]$Message)
    try {
        Rotate-LogFile -Path $logFile
        "$(Get-Date -Format o) $Message" | Out-File -FilePath $logFile -Encoding UTF8 -Append
    }
    catch {}
}

function Test-WatcherPid {
    param([string]$PidText)
    if ($PidText -match '^\d+$') {
        $process = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $PidText) -ErrorAction SilentlyContinue
        return [bool]($process -and $process.CommandLine -match 'clipboard-watch\.ps1')
    }
    return $false
}

if ($Status) {
    $watchPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($watchPid -and (Test-WatcherPid -PidText $watchPid)) {
        "clipboard_watch=running pid=$watchPid"
    }
    else {
        "clipboard_watch=stopped"
    }
    exit 0
}

if (Test-Path -LiteralPath $pidFile) {
    $oldPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($oldPid -and (Test-WatcherPid -PidText $oldPid)) {
        Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue
    }
}

"$PID" | Out-File -FilePath $pidFile -Encoding ASCII
Write-ClipLog "clipboard watcher started pid=$PID distro=$Distro poll_ms=$PollMs linux_poll_ms=$LinuxPollMs mode=bidirectional"

try {
    & wsl.exe -d $Distro -- wechatclip2win --stop 2>$null | Out-File -FilePath $logFile -Encoding UTF8 -Append
}
catch {
    Write-ClipLog "legacy_linux_watch_stop_error=$($_.Exception.Message)"
}

function Invoke-WslText {
    param([string[]]$CommandArgs)
    & wsl.exe -d $Distro -- @CommandArgs 2>$null
}

function Convert-KeyValueLines {
    param([string[]]$Lines)
    $result = @{}
    foreach ($line in $Lines) {
        if ($line -match '^([^=]+)=(.*)$') {
            $result[$matches[1]] = $matches[2]
        }
    }
    $result
}

function Initialize-LinuxClipboardHash {
    try {
        $probeOutput = @(Invoke-WslText -CommandArgs @("wechatclip2win", "--probe"))
        $probe = Convert-KeyValueLines -Lines $probeOutput
        if ($probe["kind"] -eq "text" -and $probe["hash"]) {
            Write-ClipLog "linux_clipboard_initial_hash display=$($probe["display"]) bytes=$($probe["bytes"]) sha256=$($probe["hash"])"
            return [string]$probe["hash"]
        }
        Write-ClipLog "linux_clipboard_initial_kind kind=$($probe["kind"])"
    }
    catch {
        Write-ClipLog "linux_clipboard_initial_error=$($_.Exception.Message)"
    }
    return ""
}

function Sync-WindowsToLinuxIfNeeded {
    try {
        $hasImage = [System.Windows.Forms.Clipboard]::ContainsImage()
        $hasFiles = [System.Windows.Forms.Clipboard]::ContainsFileDropList()

        if ($hasImage -or $hasFiles) {
            Write-ClipLog "syncing windows_to_linux image=$hasImage files=$hasFiles"
            Invoke-WslText -CommandArgs @("winclip2wechat") | Out-File -FilePath $logFile -Encoding UTF8 -Append
        }
    }
    catch {
        Write-ClipLog "windows_to_linux_error=$($_.Exception.Message)"
    }
}

function Sync-LinuxToWindowsIfNeeded {
    param([string]$LastHash)

    try {
        $probeOutput = @(Invoke-WslText -CommandArgs @("wechatclip2win", "--probe"))
        $probe = Convert-KeyValueLines -Lines $probeOutput

        if ($probe["kind"] -ne "text" -or -not $probe["hash"]) {
            return $LastHash
        }

        $currentHash = [string]$probe["hash"]
        if ($currentHash -eq $LastHash) {
            return $LastHash
        }

        Write-ClipLog "syncing linux_to_windows display=$($probe["display"]) bytes=$($probe["bytes"]) sha256=$currentHash"
        Invoke-WslText -CommandArgs @("wechatclip2win") | Out-File -FilePath $logFile -Encoding UTF8 -Append
        return $currentHash
    }
    catch {
        Write-ClipLog "linux_to_windows_error=$($_.Exception.Message)"
        return $LastHash
    }
}

$lastSequence = [WinClipboardNative]::GetClipboardSequenceNumber()
$lastLinuxHash = Initialize-LinuxClipboardHash
$lastLinuxPollAt = [datetime]::MinValue

while ($true) {
    Start-Sleep -Milliseconds ([Math]::Max(150, $PollMs))

    $sequence = [WinClipboardNative]::GetClipboardSequenceNumber()
    if ($sequence -ne $lastSequence) {
        $lastSequence = $sequence
        Sync-WindowsToLinuxIfNeeded
    }

    $now = Get-Date
    if (($now - $lastLinuxPollAt).TotalMilliseconds -ge [Math]::Max(300, $LinuxPollMs)) {
        $lastLinuxPollAt = $now
        $lastLinuxHash = Sync-LinuxToWindowsIfNeeded -LastHash $lastLinuxHash
    }
}
