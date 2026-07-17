param(
    [string]$Title = "",
    [string]$Body = "",
    [string]$FlashTitle = "WeChat Desktop",
    [int]$DurationMs = 7000,
    [switch]$SuppressPopup
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
$SettingsFile = Join-Path $ScriptDir "settings.json"

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

function Write-NoticeLog {
    param([string]$Message)

    try {
        Rotate-LogFile -Path $LogFile
        "$(Get-Date -Format o) $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
    catch {
        # Logging is best-effort only.
    }
}

function Get-NoticePopupEnabled {
    try {
        if (-not (Test-Path -LiteralPath $SettingsFile)) {
            return $false
        }

        $raw = Get-Content -LiteralPath $SettingsFile -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $false
        }

        $settings = $raw | ConvertFrom-Json
        $property = $settings.PSObject.Properties["NoticePopupEnabled"]
        if ($null -eq $property) {
            return $false
        }

        return [System.Convert]::ToBoolean($property.Value)
    }
    catch {
        Write-NoticeLog "settings_read_error=$($_.Exception.Message)"
        return $false
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
    Add-Type -ReferencedAssemblies @("System.Windows.Forms", "System.Drawing", "System.ComponentModel.Primitives") -TypeDefinition @"
using System;
using System.Windows.Forms;

public class WslNoActivateNoticeForm : Form {
    protected override bool ShowWithoutActivation {
        get { return true; }
    }

    protected override CreateParams CreateParams {
        get {
            const int WS_EX_TOPMOST = 0x00000008;
            const int WS_EX_TOOLWINDOW = 0x00000080;
            const int WS_EX_NOACTIVATE = 0x08000000;
            CreateParams cp = base.CreateParams;
            cp.ExStyle |= WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE;
            return cp;
        }
    }
}
"@

    [System.Windows.Forms.Application]::EnableVisualStyles()

    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $width = 330
    $height = 118
    $margin = 18

    $form = New-Object WslNoActivateNoticeForm
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
    })

    [System.Windows.Forms.Application]::Run($form)
    $timer.Dispose()
    $form.Dispose()
}

try {
    $popupEnabled = Get-NoticePopupEnabled
    $popupSuppressed = [bool]$SuppressPopup
    if ($popupSuppressed) {
        Write-NoticeLog "start title_chars=$($Title.Length) body_chars=$($Body.Length) popup=$popupEnabled suppress_popup=True"
    }
    else {
        Write-NoticeLog "start title_chars=$($Title.Length) body_chars=$($Body.Length) popup=$popupEnabled"
    }
    Flash-TargetWindow -WindowTitle $FlashTitle
    if ($popupEnabled -and -not $popupSuppressed) {
        Show-NoticeWindow -NoticeTitle $Title -NoticeBody $Body -TimeoutMs $DurationMs
    }
    elseif ($popupSuppressed) {
        Write-NoticeLog "popup=suppressed"
    }
    else {
        Write-NoticeLog "popup=disabled"
    }
    Write-NoticeLog "done"
}
catch {
    Write-NoticeLog "error=$($_.Exception.Message)"
}
