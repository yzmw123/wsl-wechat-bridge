param(
    [string]$Title = "",
    [string]$Body = "",
    [string]$FlashTitle = "WeChat Desktop",
    [int]$DurationMs = 7000
)

$ErrorActionPreference = "Stop"

function New-TextFromCodePoints {
    param([int[]]$CodePoints)

    $chars = foreach ($point in $CodePoints) {
        [char]$point
    }
    -join $chars
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = New-TextFromCodePoints @(0x6D88, 0x606F, 0x63D0, 0x9192)
}
if ([string]::IsNullOrWhiteSpace($Body)) {
    $Body = New-TextFromCodePoints @(0x6709, 0x65B0, 0x7684, 0x6D88, 0x606F)
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ScriptDir "notice.log"

function Write-NoticeLog {
    param([string]$Message)

    try {
        "$(Get-Date -Format o) $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
    catch {
        # Logging is best-effort only.
    }
}

Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class WslNoticeWin32 {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

    [StructLayout(LayoutKind.Sequential)]
    public struct FLASHWINFO {
        public UInt32 cbSize;
        public IntPtr hwnd;
        public UInt32 dwFlags;
        public UInt32 uCount;
        public UInt32 dwTimeout;
    }
}
"@

function Find-TargetWindows {
    param([string]$WindowTitle)

    $targets = New-Object System.Collections.Generic.List[System.IntPtr]
    $patterns = @(
        $WindowTitle,
        "WeChat Desktop",
        "Ubuntu-22.04"
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

    [WslNoticeWin32]::EnumWindows({
        param([IntPtr]$hWnd, [IntPtr]$lParam)

        if (-not [WslNoticeWin32]::IsWindowVisible($hWnd)) {
            return $true
        }

        $buffer = New-Object System.Text.StringBuilder 512
        [void][WslNoticeWin32]::GetWindowText($hWnd, $buffer, $buffer.Capacity)
        $text = $buffer.ToString()
        if ([string]::IsNullOrWhiteSpace($text)) {
            return $true
        }

        foreach ($pattern in $patterns) {
            if ($text.IndexOf($pattern, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $targets.Add($hWnd)
                break
            }
        }

        return $true
    }, [IntPtr]::Zero) | Out-Null

    $targets
}

function Flash-TargetWindow {
    param([string]$WindowTitle)

    $targets = Find-TargetWindows -WindowTitle $WindowTitle
    foreach ($hWnd in $targets) {
        $info = New-Object WslNoticeWin32+FLASHWINFO
        $info.cbSize = [Runtime.InteropServices.Marshal]::SizeOf($info)
        $info.hwnd = $hWnd
        # FLASHW_ALL | FLASHW_TIMERNOFG: flash caption and taskbar until foreground.
        $info.dwFlags = 0x0000000F
        $info.uCount = 12
        $info.dwTimeout = 0
        [void][WslNoticeWin32]::FlashWindowEx([ref]$info)
    }

    Write-NoticeLog "flashed=$($targets.Count)"
}

function Show-NoticeWindow {
    param(
        [string]$NoticeTitle,
        [string]$NoticeBody,
        [int]$TimeoutMs
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    [System.Windows.Forms.Application]::EnableVisualStyles()

    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $width = 330
    $height = 118
    $margin = 18

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $NoticeTitle
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
    $form.Size = New-Object System.Drawing.Size($width, $height)
    $form.Location = New-Object System.Drawing.Point(($screen.Right - $width - $margin), ($screen.Bottom - $height - $margin))
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedToolWindow
    $form.TopMost = $true
    $form.ShowInTaskbar = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = $NoticeTitle
    $titleLabel.AutoSize = $false
    $titleLabel.Location = New-Object System.Drawing.Point(18, 14)
    $titleLabel.Size = New-Object System.Drawing.Size(292, 28)
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

    $bodyLabel = New-Object System.Windows.Forms.Label
    $bodyLabel.Text = $NoticeBody
    $bodyLabel.AutoSize = $false
    $bodyLabel.Location = New-Object System.Drawing.Point(18, 50)
    $bodyLabel.Size = New-Object System.Drawing.Size(292, 32)
    $bodyLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Regular)
    $bodyLabel.ForeColor = [System.Drawing.Color]::FromArgb(70, 70, 70)

    $form.Controls.Add($titleLabel)
    $form.Controls.Add($bodyLabel)

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = [Math]::Max(1500, $TimeoutMs)
    $timer.Add_Tick({
        $timer.Stop()
        $form.Close()
    })

    $form.Add_Shown({
        try { [System.Media.SystemSounds]::Information.Play() } catch {}
        $timer.Start()
        $form.Activate()
    })

    [void]$form.ShowDialog()
    $timer.Dispose()
    $form.Dispose()
}

try {
    Write-NoticeLog "start title=$Title body=$Body"
    Flash-TargetWindow -WindowTitle $FlashTitle
    Show-NoticeWindow -NoticeTitle $Title -NoticeBody $Body -TimeoutMs $DurationMs
    Write-NoticeLog "done"
}
catch {
    Write-NoticeLog "error=$($_.Exception.Message)"
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($Body, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    }
    catch {
        Write-NoticeLog "fallback_error=$($_.Exception.Message)"
    }
}
