param(
    [string]$Distro = "Ubuntu-22.04"
)

$ErrorActionPreference = "Continue"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies @("System.Windows.Forms", "System.Drawing") -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class WslClipWidgetNative {
    [DllImport("user32.dll")]
    public static extern uint GetClipboardSequenceNumber();
    [DllImport("user32.dll")]
    public static extern bool DestroyIcon(IntPtr handle);
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string appID);
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);
}

public class NeoPanel : Panel {
    public int Radius { get; set; }
    public bool Inset { get; set; }
    public Color SurfaceColor { get; set; }
    public Color ShadowColor { get; set; }
    public Color LightColor { get; set; }

    public NeoPanel() {
        Radius = 28;
        Inset = false;
        SurfaceColor = Color.FromArgb(224, 229, 236);
        ShadowColor = Color.FromArgb(165, 163, 177, 198);
        LightColor = Color.FromArgb(175, 255, 255, 255);
        DoubleBuffered = true;
        ResizeRedraw = true;
        BackColor = SurfaceColor;
    }

    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
        e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
        DrawSurface(e.Graphics, ClientRectangle, Radius, Inset, SurfaceColor, ShadowColor, LightColor);
    }

    public static GraphicsPath RoundedPath(Rectangle rect, int radius) {
        GraphicsPath path = new GraphicsPath();
        int d = Math.Max(2, radius * 2);
        path.AddArc(rect.X, rect.Y, d, d, 180, 90);
        path.AddArc(rect.Right - d, rect.Y, d, d, 270, 90);
        path.AddArc(rect.Right - d, rect.Bottom - d, d, d, 0, 90);
        path.AddArc(rect.X, rect.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }

    public static void DrawSurface(Graphics g, Rectangle bounds, int radius, bool inset, Color fill, Color dark, Color light) {
        int pad = inset ? 7 : 12;
        Rectangle rect = new Rectangle(bounds.X + pad, bounds.Y + pad, Math.Max(8, bounds.Width - pad * 2), Math.Max(8, bounds.Height - pad * 2));
        using (GraphicsPath path = RoundedPath(rect, radius)) {
            if (inset) {
                using (SolidBrush fillBrush = new SolidBrush(fill)) {
                    g.FillPath(fillBrush, path);
                }
                using (GraphicsPath topLeft = (GraphicsPath)path.Clone())
                using (GraphicsPath bottomRight = (GraphicsPath)path.Clone())
                using (Matrix topLeftMove = new Matrix())
                using (Matrix bottomRightMove = new Matrix())
                using (Pen darkPen = new Pen(Color.FromArgb(115, 163, 177, 198), 3))
                using (Pen lightPen = new Pen(Color.FromArgb(135, 255, 255, 255), 3)) {
                    topLeftMove.Translate(-2, -2);
                    bottomRightMove.Translate(2, 2);
                    topLeft.Transform(topLeftMove);
                    bottomRight.Transform(bottomRightMove);
                    g.DrawPath(darkPen, topLeft);
                    g.DrawPath(lightPen, bottomRight);
                }
            } else {
                using (GraphicsPath shadow = (GraphicsPath)path.Clone())
                using (Matrix shadowMove = new Matrix())
                using (GraphicsPath hi = (GraphicsPath)path.Clone())
                using (Matrix hiMove = new Matrix()) {
                    shadowMove.Translate(6, 6);
                    shadow.Transform(shadowMove);
                    hiMove.Translate(-6, -6);
                    hi.Transform(hiMove);
                    using (SolidBrush shadowBrush = new SolidBrush(dark))
                    using (SolidBrush lightBrush = new SolidBrush(light))
                    using (SolidBrush fillBrush = new SolidBrush(fill)) {
                        g.FillPath(shadowBrush, shadow);
                        g.FillPath(lightBrush, hi);
                        g.FillPath(fillBrush, path);
                    }
                }
            }
        }
    }
}

public class NeoButton : Control {
    private bool pressed = false;
    private bool hover = false;
    public int Radius { get; set; }
    public Color SurfaceColor { get; set; }
    public Color FillColor { get; set; }
    public Color TextColor { get; set; }
    public Color DisabledTextColor { get; set; }
    public Color ShadowColor { get; set; }
    public Color LightColor { get; set; }

    public NeoButton() {
        Radius = 16;
        SurfaceColor = Color.FromArgb(224, 229, 236);
        FillColor = Color.FromArgb(224, 229, 236);
        TextColor = Color.FromArgb(61, 72, 82);
        DisabledTextColor = Color.FromArgb(148, 163, 184);
        ShadowColor = Color.FromArgb(165, 163, 177, 198);
        LightColor = Color.FromArgb(175, 255, 255, 255);
        DoubleBuffered = true;
        ResizeRedraw = true;
        Cursor = Cursors.Hand;
        BackColor = SurfaceColor;
        Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Bold);
        Size = new Size(120, 46);
        SetStyle(ControlStyles.Selectable, true);
    }

    protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { hover = false; pressed = false; Invalidate(); base.OnMouseLeave(e); }
    protected override void OnMouseDown(MouseEventArgs e) { if (Enabled && e.Button == MouseButtons.Left) { pressed = true; Invalidate(); } base.OnMouseDown(e); }
    protected override void OnMouseUp(MouseEventArgs e) { if (pressed) { pressed = false; Invalidate(); } base.OnMouseUp(e); }
    protected override void OnEnabledChanged(EventArgs e) { Invalidate(); base.OnEnabledChanged(e); }

    protected override void OnPaint(PaintEventArgs e) {
        e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
        Color fill = Enabled ? FillColor : Color.FromArgb(216, 222, 230);
        Color text = Enabled ? TextColor : DisabledTextColor;
        Color dark = ShadowColor;
        Color light = LightColor;
        if (FillColor.ToArgb() != SurfaceColor.ToArgb()) {
            dark = Color.FromArgb(120, Math.Max(0, FillColor.R - 45), Math.Max(0, FillColor.G - 45), Math.Max(0, FillColor.B - 45));
            light = Color.FromArgb(110, 255, 255, 255);
        }
        NeoPanel.DrawSurface(e.Graphics, ClientRectangle, Radius, pressed, fill, dark, light);
        Rectangle textRect = new Rectangle(10, 0, Width - 20, Height);
        if (hover && !pressed && Enabled) textRect.Y -= 1;
        TextRenderer.DrawText(e.Graphics, Text, Font, textRect, text, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
    }
}
"@

[System.Windows.Forms.Application]::EnableVisualStyles()
[void][WslClipWidgetNative]::SetCurrentProcessExplicitAppUserModelID("WslPrivate.ClipboardWidget")

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $scriptDir "clipboard-widget.log"
$iconSvgPath = Join-Path $scriptDir "wsl-clip-cube.svg"
$iconPngPath = Join-Path $scriptDir "wsl-clip-cube.png"
$iconIcoPath = Join-Path $scriptDir "wsl-clip-cube.ico"
$iconVersionPath = Join-Path $scriptDir "wsl-clip-cube.icon-v2"

$surfaceColor = [System.Drawing.Color]::FromArgb(224, 229, 236)
$foregroundColor = [System.Drawing.Color]::FromArgb(61, 72, 82)
$mutedColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
$accentColor = [System.Drawing.Color]::FromArgb(108, 99, 255)
$successColor = [System.Drawing.Color]::FromArgb(56, 178, 172)
$watchOkColor = [System.Drawing.Color]::FromArgb(34, 197, 94)
$watchWarnColor = [System.Drawing.Color]::FromArgb(245, 158, 11)

$script:PayloadKind = "empty"
$script:PayloadText = ""
$script:PayloadImage = $null
$script:PayloadFiles = @()
$script:SuppressTextChanged = $false
$script:LastClipboardSequence = [WslClipWidgetNative]::GetClipboardSequenceNumber()
$script:LastWatchStatusAt = [datetime]::MinValue

function Write-WidgetLog {
    param([string]$Message)
    try {
        "$(Get-Date -Format o) $Message" | Out-File -LiteralPath $logFile -Encoding UTF8 -Append
    }
    catch {}
}

function New-WidgetIconBitmap {
    param([int]$Size)

    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $scale = $Size / 256.0
    $tileInset = [Math]::Max(1, [int](12 * $scale))
    $tileRect = New-Object System.Drawing.Rectangle -ArgumentList $tileInset, $tileInset, ($Size - ($tileInset * 2)), ($Size - ($tileInset * 2))
    $tileRadius = [Math]::Max(4, [int](44 * $scale))

    $shadowRect = New-Object System.Drawing.Rectangle -ArgumentList ($tileRect.X + [int](6 * $scale)), ($tileRect.Y + [int](7 * $scale)), $tileRect.Width, $tileRect.Height
    $shadowPath = [NeoPanel]::RoundedPath($shadowRect, $tileRadius)
    $tilePath = [NeoPanel]::RoundedPath($tileRect, $tileRadius)
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 139, 155, 183))
    $tileBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($tileRect, [System.Drawing.Color]::FromArgb(247, 251, 255), [System.Drawing.Color]::FromArgb(197, 215, 235), [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
    $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 255, 255, 255), [Math]::Max(1, [int](2 * $scale)))
    $graphics.FillPath($shadowBrush, $shadowPath)
    $graphics.FillPath($tileBrush, $tilePath)
    $graphics.DrawPath($borderPen, $tilePath)
    $shadowBrush.Dispose()
    $tileBrush.Dispose()
    $borderPen.Dispose()
    $shadowPath.Dispose()
    $tilePath.Dispose()

    $cubeShadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(45, 13, 82, 127))
    $graphics.FillEllipse($cubeShadowBrush, [float](52 * $scale), [float](193 * $scale), [float](152 * $scale), [float](24 * $scale))
    $cubeShadowBrush.Dispose()

    function New-IconPoint {
        param([double]$X, [double]$Y)
        return (New-Object System.Drawing.PointF -ArgumentList ([float]($X * $scale)), ([float]($Y * $scale)))
    }

    $top = [System.Drawing.PointF[]]@(
        (New-IconPoint 61 89),
        (New-IconPoint 128 50),
        (New-IconPoint 195 89),
        (New-IconPoint 128 128)
    )
    $left = [System.Drawing.PointF[]]@(
        (New-IconPoint 61 93),
        (New-IconPoint 128 132),
        (New-IconPoint 128 205),
        (New-IconPoint 61 166)
    )
    $right = [System.Drawing.PointF[]]@(
        (New-IconPoint 195 93),
        (New-IconPoint 128 132),
        (New-IconPoint 128 205),
        (New-IconPoint 195 166)
    )

    $topBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(236, 13, 82, 127))
    $leftBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 13, 82, 127))
    $rightBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(125, 13, 82, 127))
    $edgePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 8, 55, 86), [Math]::Max(1, [int](2 * $scale)))
    $graphics.FillPolygon($leftBrush, $left)
    $graphics.FillPolygon($rightBrush, $right)
    $graphics.FillPolygon($topBrush, $top)
    $graphics.DrawPolygon($edgePen, $top)
    $graphics.DrawLine($edgePen, (New-IconPoint 61 93), (New-IconPoint 128 132))
    $graphics.DrawLine($edgePen, (New-IconPoint 195 93), (New-IconPoint 128 132))
    $topBrush.Dispose()
    $leftBrush.Dispose()
    $rightBrush.Dispose()
    $edgePen.Dispose()
    $graphics.Dispose()

    return $bitmap
}

function Write-MultiSizeIcon {
    param(
        [string]$Path,
        [object[]]$Entries
    )

    $stream = [System.IO.File]::Create($Path)
    $writer = New-Object System.IO.BinaryWriter($stream)
    try {
        $writer.Write([UInt16]0)
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]$Entries.Count)
        $offset = 6 + ($Entries.Count * 16)
        foreach ($entry in $Entries) {
            $size = [int]$entry.Size
            $bytes = [byte[]]$entry.Bytes
            $widthByte = if ($size -ge 256) { 0 } else { $size }
            $heightByte = if ($size -ge 256) { 0 } else { $size }
            $writer.Write([byte]$widthByte)
            $writer.Write([byte]$heightByte)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            $writer.Write([UInt16]1)
            $writer.Write([UInt16]32)
            $writer.Write([UInt32]$bytes.Length)
            $writer.Write([UInt32]$offset)
            $offset += $bytes.Length
        }
        foreach ($entry in $Entries) {
            $writer.Write([byte[]]$entry.Bytes)
        }
    }
    finally {
        $writer.Close()
        $stream.Close()
    }
}

function New-AppIconAssets {
    if ((Test-Path -LiteralPath $iconSvgPath) -and (Test-Path -LiteralPath $iconPngPath) -and (Test-Path -LiteralPath $iconIcoPath) -and (Test-Path -LiteralPath $iconVersionPath)) {
        return
    }
    $svg = @'
<svg class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="17053" height="128" width="128"><path d="M136.3 319.4c44.8 26.3 86.9 51.1 129.1 75.9 67.8 40 135.7 80 203.6 119.6 8.9 5.3 14.5 10.5 14.5 22.7-0.6 137.1-0.4 274.2-0.4 411.3 0 3.5-0.6 7.1-0.9 12.5-6.9-3.5-12.2-6-17.1-9.1-105-61.7-209.8-123.5-314.7-185.3-8.4-4.9-15.4-9-15.4-21.9 0.7-137.8 0.4-275.5 0.4-413.2-0.1-3 0.5-6 0.9-12.5z" fill="#0D527F" opacity=".65" p-id="17054"></path><path d="M886.6 320.3c0.5 8.2 0.9 14.1 0.9 20.1 0.1 133.9 0 268.1 0.2 402 0.1 9.9-1.3 16.9-11 22.6C767.9 828.5 659.5 892.7 551 956.6c-2.5 1.5-5.3 2.5-9.8 4.8-0.6-6.7-1.3-11.9-1.3-17.1-0.1-133.9 0.2-268-0.3-401.9-0.1-13.5 3.3-21.1 15.1-27.8 104.7-60.9 208.9-122.8 313.2-184.2 5.5-3.3 11.3-6.1 18.7-10.1z" fill="#0D527F" opacity=".4" p-id="17055"></path><path d="M166.1 267.9c7.4-4.6 12.8-8.3 18.4-11.5 103.7-61.2 207.7-122.3 311.4-183.6 9.2-5.6 16.7-8.9 27.9-2.3C631 134.4 738.6 197.5 846 260.9c3.1 1.8 5.9 4 10.3 7.1-4 3.2-6.8 6.2-10.1 8.1C738.7 339.6 631.3 403 523.6 465.8c-5.9 3.5-16.8 4.1-22.5 0.9-109.8-64-219.3-128.7-328.9-193.4-1.3-0.8-2.5-2.2-6.1-5.4z" fill="#0D527F" opacity=".9" p-id="17056"></path></svg>
'@
    $svg | Out-File -LiteralPath $iconSvgPath -Encoding UTF8

    $sizes = @(16, 24, 32, 48, 64, 128, 256)
    $pngEntries = New-Object System.Collections.ArrayList
    foreach ($size in $sizes) {
        $bitmap = New-WidgetIconBitmap -Size $size
        $memory = New-Object System.IO.MemoryStream
        $bitmap.Save($memory, [System.Drawing.Imaging.ImageFormat]::Png)
        $bytes = $memory.ToArray()
        [void]$pngEntries.Add(@{ Size = $size; Bytes = $bytes })
        if ($size -eq 256) {
            $bitmap.Save($iconPngPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        $memory.Dispose()
        $bitmap.Dispose()
    }
    Write-MultiSizeIcon -Path $iconIcoPath -Entries $pngEntries
    "v2" | Out-File -LiteralPath $iconVersionPath -Encoding ASCII
}

function Remove-NulText {
    param([object[]]$Lines)
    $clean = @()
    foreach ($line in $Lines) {
        $text = [string]$line
        $text = $text -replace "`0", ""
        $text = $text -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''
        $trimmed = $text.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        if ($trimmed -match '^\s*wsl:') { continue }
        if ($trimmed -match 'localhost' -and $trimmed -match '(WSL|NAT|proxy|代理|localhost)') { continue }
        if ($trimmed -match 'screen size is bogus') { continue }
        if ($trimmed -match '[�□]' -and $trimmed -match '(WSL|NAT|localhost|proxy)') { continue }
        $clean += $trimmed
    }
    return $clean
}

function Get-PayloadSummary {
    switch ($script:PayloadKind) {
        "text" {
            $chars = $script:PayloadText.Length
            if ($chars -eq 0) { return "文本为空" }
            return "文本 $chars 字"
        }
        "image" {
            if ($script:PayloadImage) { return "图片 $($script:PayloadImage.Width)x$($script:PayloadImage.Height)" }
            return "图片"
        }
        "files" { return "文件 $($script:PayloadFiles.Count) 个" }
        default { return "没有可同步的内容" }
    }
}

function Set-Status {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color = $foregroundColor
    )
    $statusLabel.Text = $Message
    $statusLabel.ForeColor = $Color
}

function Test-ClipboardWatcherPid {
    param([string]$PidText)
    if ($PidText -notmatch '^\d+$') { return $false }
    try {
        $pidValue = [int]$PidText
        $process = Get-CimInstance Win32_Process -Filter "ProcessId=$pidValue" -ErrorAction SilentlyContinue
        if ($process -and $process.CommandLine -like "*clipboard-watch.ps1*") {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

function Get-ClipboardWatcherStatus {
    $watchScriptPath = Join-Path $scriptDir "clipboard-watch.ps1"
    $watchPidFile = Join-Path $scriptDir "clipboard-watch.pid"

    if (-not (Test-Path -LiteralPath $watchScriptPath)) {
        return @{
            Running = $false
            Pid = ""
            Text = "剪切板监听：脚本缺失"
        }
    }

    $watchPid = Get-Content -LiteralPath $watchPidFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($watchPid -and (Test-ClipboardWatcherPid -PidText $watchPid)) {
        return @{
            Running = $true
            Pid = [string]$watchPid
            Text = "剪切板监听：正常 pid=$watchPid"
        }
    }

    return @{
        Running = $false
        Pid = ""
        Text = "剪切板监听：未运行"
    }
}

function Update-ClipboardWatcherStatus {
    $watch = Get-ClipboardWatcherStatus
    if ($watch.Running) {
        $watchDotLabel.ForeColor = $watchOkColor
        $watchStatusLabel.Text = $watch.Text
        $watchStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(28, 110, 68)
        $watchStartButton.Text = "停止监听"
        $watchStartButton.FillColor = $surfaceColor
        $watchStartButton.TextColor = $foregroundColor
        $watchStartButton.Invalidate()
    }
    else {
        $watchDotLabel.ForeColor = $watchWarnColor
        $watchStatusLabel.Text = $watch.Text
        $watchStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(133, 77, 14)
        $watchStartButton.Text = "启动监听"
        $watchStartButton.FillColor = $watchWarnColor
        $watchStartButton.TextColor = [System.Drawing.Color]::White
        $watchStartButton.Invalidate()
    }
}

function Invoke-ClipboardWatcherStart {
    $watch = Get-ClipboardWatcherStatus
    if ($watch.Running) {
        Update-ClipboardWatcherStatus
        Set-Status "剪切板监听已经正常运行" ([System.Drawing.Color]::FromArgb(28, 110, 68))
        return
    }

    $watchLauncherPath = Join-Path $scriptDir "start-clipboard-watch-hidden.vbs"
    if (-not (Test-Path -LiteralPath $watchLauncherPath)) {
        Update-ClipboardWatcherStatus
        Set-Status "启动监听失败：启动脚本不存在" ([System.Drawing.Color]::Firebrick)
        Write-WidgetLog "watch_start_missing_launcher=$watchLauncherPath"
        return
    }

    try {
        $watchStartButton.Enabled = $false
        $watchStatusLabel.Text = "剪切板监听：正在启动..."
        $watchStatusLabel.ForeColor = $mutedColor
        $watchDotLabel.ForeColor = $watchWarnColor
        [System.Windows.Forms.Application]::DoEvents()
        Start-Process -FilePath "wscript.exe" -ArgumentList @("//B", "`"$watchLauncherPath`"") -WindowStyle Hidden | Out-Null
        Start-Sleep -Milliseconds 1200
        Update-ClipboardWatcherStatus
        $watch = Get-ClipboardWatcherStatus
        if ($watch.Running) {
            Set-Status "剪切板监听已启动" ([System.Drawing.Color]::FromArgb(28, 110, 68))
            $outputBox.Text = "已启动统一剪切板监听"
            Write-WidgetLog "watch_start_ok pid=$($watch.Pid)"
        }
        else {
            Set-Status "监听启动后仍未运行" ([System.Drawing.Color]::Firebrick)
            Write-WidgetLog "watch_start_failed_not_running"
        }
    }
    catch {
        Set-Status "启动监听失败：$($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
        Write-WidgetLog "watch_start_error=$($_.Exception.Message)"
    }
    finally {
        $watchStartButton.Enabled = $true
    }
}

function Invoke-ClipboardWatcherStop {
    $watch = Get-ClipboardWatcherStatus
    if (-not $watch.Running) {
        Update-ClipboardWatcherStatus
        Set-Status "剪切板监听当前未运行" ([System.Drawing.Color]::FromArgb(133, 77, 14))
        return
    }

    $watchStopPath = Join-Path $scriptDir "stop-clipboard-watch.cmd"
    if (-not (Test-Path -LiteralPath $watchStopPath)) {
        Update-ClipboardWatcherStatus
        Set-Status "停止监听失败：停止脚本不存在" ([System.Drawing.Color]::Firebrick)
        Write-WidgetLog "watch_stop_missing_script=$watchStopPath"
        return
    }

    try {
        $watchStartButton.Enabled = $false
        $watchStatusLabel.Text = "剪切板监听：正在停止..."
        $watchStatusLabel.ForeColor = $mutedColor
        [System.Windows.Forms.Application]::DoEvents()
        $output = & $watchStopPath 2>&1
        $cleanOutput = Remove-NulText -Lines $output
        $outputBox.Text = ($cleanOutput -join [Environment]::NewLine)
        Start-Sleep -Milliseconds 500
        Update-ClipboardWatcherStatus
        Set-Status "剪切板监听已停止" ([System.Drawing.Color]::FromArgb(133, 77, 14))
        Write-WidgetLog "watch_stop_ok pid=$($watch.Pid)"
    }
    catch {
        Set-Status "停止监听失败：$($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
        Write-WidgetLog "watch_stop_error=$($_.Exception.Message)"
    }
    finally {
        $watchStartButton.Enabled = $true
    }
}

function Invoke-ClipboardWatcherToggle {
    $watch = Get-ClipboardWatcherStatus
    if ($watch.Running) {
        Invoke-ClipboardWatcherStop
    }
    else {
        Invoke-ClipboardWatcherStart
    }
}

function Show-PayloadView {
    param([string]$Kind)
    $textBox.Visible = ($Kind -eq "text" -or $Kind -eq "empty")
    $pictureBox.Visible = ($Kind -eq "image")
    $fileList.Visible = ($Kind -eq "files")
}

function Set-TextPayload {
    param([string]$Text)
    $script:PayloadKind = "text"
    $script:PayloadText = $Text
    $script:PayloadImage = $null
    $script:PayloadFiles = @()
    $script:SuppressTextChanged = $true
    $textBox.Text = $Text
    $script:SuppressTextChanged = $false
    if ($pictureBox.Image) {
        $pictureBox.Image.Dispose()
        $pictureBox.Image = $null
    }
    $fileList.Items.Clear()
    Show-PayloadView "text"
    Set-Status "已读取：$(Get-PayloadSummary)"
}

function Set-ImagePayload {
    param([System.Drawing.Image]$Image)
    $script:PayloadKind = "image"
    $script:PayloadText = ""
    if ($script:PayloadImage) { $script:PayloadImage.Dispose() }
    $script:PayloadImage = New-Object System.Drawing.Bitmap($Image)
    $script:PayloadFiles = @()
    if ($pictureBox.Image) { $pictureBox.Image.Dispose() }
    $pictureBox.Image = New-Object System.Drawing.Bitmap($Image)
    $script:SuppressTextChanged = $true
    $textBox.Text = ""
    $script:SuppressTextChanged = $false
    $fileList.Items.Clear()
    Show-PayloadView "image"
    Set-Status "已读取：$(Get-PayloadSummary)"
}

function Set-FilePayload {
    param([string[]]$Files)
    $script:PayloadKind = "files"
    $script:PayloadText = ""
    if ($script:PayloadImage) {
        $script:PayloadImage.Dispose()
        $script:PayloadImage = $null
    }
    $script:PayloadFiles = @($Files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($pictureBox.Image) {
        $pictureBox.Image.Dispose()
        $pictureBox.Image = $null
    }
    $script:SuppressTextChanged = $true
    $textBox.Text = ""
    $script:SuppressTextChanged = $false
    $fileList.Items.Clear()
    foreach ($file in $script:PayloadFiles) { [void]$fileList.Items.Add($file) }
    Show-PayloadView "files"
    Set-Status "已读取：$(Get-PayloadSummary)"
}

function Set-EmptyPayload {
    $script:PayloadKind = "empty"
    $script:PayloadText = ""
    if ($script:PayloadImage) {
        $script:PayloadImage.Dispose()
        $script:PayloadImage = $null
    }
    if ($pictureBox.Image) {
        $pictureBox.Image.Dispose()
        $pictureBox.Image = $null
    }
    $script:PayloadFiles = @()
    $script:SuppressTextChanged = $true
    $textBox.Text = ""
    $script:SuppressTextChanged = $false
    $fileList.Items.Clear()
    Show-PayloadView "empty"
    Set-Status "当前剪切板为空或格式暂不支持" ([System.Drawing.Color]::FromArgb(120, 72, 40))
}

function Read-ClipboardIntoWidget {
    try {
        if ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
            $files = @()
            foreach ($item in [System.Windows.Forms.Clipboard]::GetFileDropList()) { $files += [string]$item }
            if ($files.Count -gt 0) {
                Set-FilePayload -Files $files
                return
            }
        }
        if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
            Set-ImagePayload -Image ([System.Windows.Forms.Clipboard]::GetImage())
            return
        }
        if ([System.Windows.Forms.Clipboard]::ContainsText()) {
            Set-TextPayload -Text ([System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::UnicodeText)
            )
            return
        }
        Set-EmptyPayload
    }
    catch {
        Set-Status "读取失败：$($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
        Write-WidgetLog "read_error=$($_.Exception.Message)"
    }
}

function Restore-PayloadToWindowsClipboard {
    switch ($script:PayloadKind) {
        "text" {
            [System.Windows.Forms.Clipboard]::SetText($script:PayloadText, [System.Windows.Forms.TextDataFormat]::UnicodeText)
            return $true
        }
        "image" {
            if (-not $script:PayloadImage) { return $false }
            [System.Windows.Forms.Clipboard]::SetImage($script:PayloadImage)
            return $true
        }
        "files" {
            if ($script:PayloadFiles.Count -eq 0) { return $false }
            $collection = New-Object System.Collections.Specialized.StringCollection
            foreach ($file in $script:PayloadFiles) { [void]$collection.Add($file) }
            [System.Windows.Forms.Clipboard]::SetFileDropList($collection)
            return $true
        }
        default { return $false }
    }
}

function Set-ButtonsEnabled {
    param([bool]$Enabled)
    $refreshButton.Enabled = $Enabled
    $syncButton.Enabled = $Enabled
    $pasteButton.Enabled = $Enabled
}

function Invoke-WslClipboardSync {
    param([switch]$Paste)
    if ($script:PayloadKind -eq "empty") {
        Set-Status "没有可同步的内容" ([System.Drawing.Color]::Firebrick)
        return
    }
    if (-not (Restore-PayloadToWindowsClipboard)) {
        Set-Status "内容恢复到 Windows 剪切板失败" ([System.Drawing.Color]::Firebrick)
        return
    }
    Set-ButtonsEnabled $false
    Set-Status "正在同步到 WSL..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        $args = @("-d", $Distro, "--", "winclip2wechat")
        if ($Paste) { $args += "--paste" }
        $output = & wsl.exe @args 2>&1
        $exitCode = $LASTEXITCODE
        $cleanOutput = Remove-NulText -Lines $output
        $outputBox.Text = ($cleanOutput -join [Environment]::NewLine)
        if ($exitCode -eq 0) {
            $message = "已同步到 WSL：$(Get-PayloadSummary)"
            if ($Paste) { $message = "已同步并发送粘贴：$(Get-PayloadSummary)" }
            Set-Status $message ([System.Drawing.Color]::FromArgb(28, 110, 68))
            Write-WidgetLog "sync_ok kind=$($script:PayloadKind) paste=$Paste summary=$(Get-PayloadSummary)"
        }
        else {
            Set-Status "同步失败，退出码 $exitCode" ([System.Drawing.Color]::Firebrick)
            Write-WidgetLog "sync_failed code=$exitCode kind=$($script:PayloadKind)"
        }
    }
    catch {
        Set-Status "同步失败：$($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
        Write-WidgetLog "sync_error=$($_.Exception.Message)"
    }
    finally {
        $script:LastClipboardSequence = [WslClipWidgetNative]::GetClipboardSequenceNumber()
        Set-ButtonsEnabled $true
    }
}

function Invoke-WeChatStart {
    try {
        $startButton.Enabled = $false
        Set-Status "正在启动应用..."
        Start-Process -FilePath "wsl.exe" -ArgumentList @("-d", $Distro, "--", "wechat-desktop") -WindowStyle Hidden | Out-Null
        $outputBox.Text = "已发送启动命令：wsl -d $Distro -- wechat-desktop"
        Set-Status "已发送启动应用命令" ([System.Drawing.Color]::FromArgb(28, 110, 68))
        Write-WidgetLog "app_start_requested distro=$Distro"
    }
    catch {
        Set-Status "启动失败：$($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
        Write-WidgetLog "app_start_error=$($_.Exception.Message)"
    }
    finally {
        $startButton.Enabled = $true
    }
}

function Invoke-WeChatStop {
    try {
        $stopButton.Enabled = $false
        Set-Status "正在关闭应用..."
        [System.Windows.Forms.Application]::DoEvents()
        $output = & wsl.exe -d $Distro -- wechat-desktop-stop 2>&1
        $exitCode = $LASTEXITCODE
        $cleanOutput = Remove-NulText -Lines $output
        $outputBox.Text = ($cleanOutput -join [Environment]::NewLine)
        if ($exitCode -eq 0) {
            Set-Status "已关闭应用" ([System.Drawing.Color]::FromArgb(28, 110, 68))
            Write-WidgetLog "app_stop_ok distro=$Distro"
        }
        else {
            Set-Status "关闭命令返回退出码 $exitCode" ([System.Drawing.Color]::Firebrick)
            Write-WidgetLog "app_stop_failed code=$exitCode"
        }
    }
    catch {
        Set-Status "关闭失败：$($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
        Write-WidgetLog "app_stop_error=$($_.Exception.Message)"
    }
    finally {
        $stopButton.Enabled = $true
    }
}

function New-NeoButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [System.Drawing.Color]$Fill = $surfaceColor,
        [System.Drawing.Color]$TextColor = $foregroundColor
    )
    $button = New-Object NeoButton
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.FillColor = $Fill
    $button.TextColor = $TextColor
    $button.SurfaceColor = $surfaceColor
    return $button
}

function New-NeoPanel {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$Radius = 28,
        [switch]$Inset
    )
    $panel = New-Object NeoPanel
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size = New-Object System.Drawing.Size($Width, $Height)
    $panel.Radius = $Radius
    $panel.Inset = [bool]$Inset
    $panel.SurfaceColor = $surfaceColor
    return $panel
}

New-AppIconAssets

$form = New-Object System.Windows.Forms.Form
$form.Text = "WSL 剪切板同步"
$form.StartPosition = "CenterScreen"
$form.ClientSize = New-Object System.Drawing.Size(540, 720)
$form.MinimumSize = New-Object System.Drawing.Size(560, 760)
$form.TopMost = $true
$form.KeyPreview = $true
$form.AllowDrop = $true
$form.BackColor = $surfaceColor
$form.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$form.Icon = New-Object System.Drawing.Icon($iconIcoPath)
$form.Add_HandleCreated({
    if ($form.Icon) {
        [void][WslClipWidgetNative]::SendMessage($form.Handle, 0x0080, [IntPtr]0, $form.Icon.Handle)
        [void][WslClipWidgetNative]::SendMessage($form.Handle, 0x0080, [IntPtr]1, $form.Icon.Handle)
    }
})

$headerPanel = New-NeoPanel -X 18 -Y 18 -Width 504 -Height 116 -Radius 32
$form.Controls.Add($headerPanel)

$iconWell = New-NeoPanel -X 22 -Y 22 -Width 72 -Height 72 -Radius 22 -Inset
$headerPanel.Controls.Add($iconWell)

$iconBox = New-Object System.Windows.Forms.PictureBox
$iconBox.SizeMode = "Zoom"
$iconBox.BackColor = $surfaceColor
$iconBox.Location = New-Object System.Drawing.Point(16, 16)
$iconBox.Size = New-Object System.Drawing.Size(40, 40)
$iconStream = [System.IO.File]::OpenRead($iconPngPath)
$iconImage = [System.Drawing.Image]::FromStream($iconStream)
$iconBox.Image = New-Object System.Drawing.Bitmap($iconImage)
$iconImage.Dispose()
$iconStream.Close()
$iconWell.Controls.Add($iconBox)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "WSL 剪切板同步"
$titleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 15.5, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $foregroundColor
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$titleLabel.Location = New-Object System.Drawing.Point(112, 28)
$titleLabel.Size = New-Object System.Drawing.Size(250, 30)
$headerPanel.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "文字 / 图片 / 文件，一键送进 Linux"
$subtitleLabel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$subtitleLabel.ForeColor = $mutedColor
$subtitleLabel.BackColor = [System.Drawing.Color]::Transparent
$subtitleLabel.Location = New-Object System.Drawing.Point(114, 62)
$subtitleLabel.Size = New-Object System.Drawing.Size(260, 22)
$headerPanel.Controls.Add($subtitleLabel)

$topMostButton = New-NeoButton -Text "置顶开" -X 392 -Y 36 -Width 84 -Height 44
$topMostButton.Add_Click({
    $form.TopMost = -not $form.TopMost
    $topMostButton.Text = if ($form.TopMost) { "置顶开" } else { "置顶关" }
    Set-Status ($(if ($form.TopMost) { "窗口已置顶" } else { "窗口已取消置顶" }))
})
$headerPanel.Controls.Add($topMostButton)

$startButton = New-NeoButton -Text "启动应用" -X 18 -Y 150 -Width 246 -Height 54 -Fill $accentColor -TextColor ([System.Drawing.Color]::White)
$startButton.Add_Click({ Invoke-WeChatStart })
$form.Controls.Add($startButton)

$stopButton = New-NeoButton -Text "关闭应用" -X 276 -Y 150 -Width 246 -Height 54
$stopButton.Add_Click({ Invoke-WeChatStop })
$form.Controls.Add($stopButton)

$watchPanel = New-NeoPanel -X 18 -Y 216 -Width 354 -Height 52 -Radius 22 -Inset
$form.Controls.Add($watchPanel)

$watchDotLabel = New-Object System.Windows.Forms.Label
$watchDotLabel.Text = "●"
$watchDotLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$watchDotLabel.ForeColor = $watchWarnColor
$watchDotLabel.BackColor = [System.Drawing.Color]::Transparent
$watchDotLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$watchDotLabel.Location = New-Object System.Drawing.Point(24, 15)
$watchDotLabel.Size = New-Object System.Drawing.Size(18, 22)
$watchPanel.Controls.Add($watchDotLabel)

$watchStatusLabel = New-Object System.Windows.Forms.Label
$watchStatusLabel.Text = "剪切板监听：检查中..."
$watchStatusLabel.AutoEllipsis = $true
$watchStatusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$watchStatusLabel.Location = New-Object System.Drawing.Point(50, 15)
$watchStatusLabel.Size = New-Object System.Drawing.Size(275, 22)
$watchStatusLabel.ForeColor = $mutedColor
$watchStatusLabel.BackColor = [System.Drawing.Color]::Transparent
$watchPanel.Controls.Add($watchStatusLabel)

$watchStartButton = New-NeoButton -Text "启动监听" -X 392 -Y 220 -Width 130 -Height 44
$watchStartButton.Radius = 14
$watchStartButton.Add_Click({ Invoke-ClipboardWatcherToggle })
$form.Controls.Add($watchStartButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "正在读取剪切板..."
$statusLabel.AutoEllipsis = $true
$statusLabel.Location = New-Object System.Drawing.Point(32, 290)
$statusLabel.Size = New-Object System.Drawing.Size(476, 22)
$statusLabel.ForeColor = $foregroundColor
$statusLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($statusLabel)

$inputPanel = New-NeoPanel -X 18 -Y 318 -Width 504 -Height 190 -Radius 28 -Inset
$form.Controls.Add($inputPanel)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.AcceptsReturn = $true
$textBox.AcceptsTab = $true
$textBox.ScrollBars = "Vertical"
$textBox.BorderStyle = "None"
$textBox.BackColor = $surfaceColor
$textBox.ForeColor = $foregroundColor
$textBox.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9.5)
$textBox.Location = New-Object System.Drawing.Point(28, 26)
$textBox.Size = New-Object System.Drawing.Size(448, 138)
$textBox.Add_TextChanged({
    if ($script:SuppressTextChanged) { return }
    $script:PayloadKind = "text"
    $script:PayloadText = $textBox.Text
    $script:PayloadImage = $null
    $script:PayloadFiles = @()
    Show-PayloadView "text"
    Set-Status "已编辑：$(Get-PayloadSummary)"
})
$inputPanel.Controls.Add($textBox)

$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.BackColor = $surfaceColor
$pictureBox.SizeMode = "Zoom"
$pictureBox.Location = $textBox.Location
$pictureBox.Size = $textBox.Size
$pictureBox.Visible = $false
$inputPanel.Controls.Add($pictureBox)

$fileList = New-Object System.Windows.Forms.ListBox
$fileList.BorderStyle = "None"
$fileList.BackColor = $surfaceColor
$fileList.ForeColor = $foregroundColor
$fileList.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$fileList.Location = $textBox.Location
$fileList.Size = $textBox.Size
$fileList.Visible = $false
$inputPanel.Controls.Add($fileList)

$refreshButton = New-NeoButton -Text "读取剪切板" -X 18 -Y 524 -Width 158 -Height 50
$refreshButton.Add_Click({
    Read-ClipboardIntoWidget
    $script:LastClipboardSequence = [WslClipWidgetNative]::GetClipboardSequenceNumber()
})
$form.Controls.Add($refreshButton)

$syncButton = New-NeoButton -Text "同步到 WSL" -X 191 -Y 524 -Width 158 -Height 50 -Fill $accentColor -TextColor ([System.Drawing.Color]::White)
$syncButton.Add_Click({ Invoke-WslClipboardSync })
$form.Controls.Add($syncButton)

$pasteButton = New-NeoButton -Text "同步并粘贴" -X 364 -Y 524 -Width 158 -Height 50 -Fill $successColor -TextColor ([System.Drawing.Color]::White)
$pasteButton.Add_Click({ Invoke-WslClipboardSync -Paste })
$form.Controls.Add($pasteButton)

$outputPanel = New-NeoPanel -X 18 -Y 590 -Width 504 -Height 86 -Radius 24 -Inset
$form.Controls.Add($outputPanel)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ReadOnly = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.BorderStyle = "None"
$outputBox.BackColor = $surfaceColor
$outputBox.ForeColor = $mutedColor
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 8.5)
$outputBox.Location = New-Object System.Drawing.Point(24, 20)
$outputBox.Size = New-Object System.Drawing.Size(456, 48)
$outputPanel.Controls.Add($outputBox)

$hintLabel = New-Object System.Windows.Forms.Label
$hintLabel.Text = "Ctrl+V 或拖文件到窗口；同步后去 Linux 里粘贴。"
$hintLabel.AutoEllipsis = $true
$hintLabel.Location = New-Object System.Drawing.Point(30, 688)
$hintLabel.Size = New-Object System.Drawing.Size(480, 18)
$hintLabel.ForeColor = $mutedColor
$hintLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($hintLabel)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 700
$timer.Add_Tick({
    try {
        $sequence = [WslClipWidgetNative]::GetClipboardSequenceNumber()
        if ($sequence -ne $script:LastClipboardSequence -and -not $textBox.Focused) {
            $script:LastClipboardSequence = $sequence
            Read-ClipboardIntoWidget
        }
        $now = Get-Date
        if (($now - $script:LastWatchStatusAt).TotalMilliseconds -ge 2500) {
            $script:LastWatchStatusAt = $now
            Update-ClipboardWatcherStatus
        }
    }
    catch {}
})

$form.Add_KeyDown({
    if ($_.Control -and $_.KeyCode -eq [System.Windows.Forms.Keys]::V) {
        if (-not $textBox.Focused -or [System.Windows.Forms.Clipboard]::ContainsImage() -or [System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
            Read-ClipboardIntoWidget
            $script:LastClipboardSequence = [WslClipWidgetNative]::GetClipboardSequenceNumber()
            $_.Handled = $true
        }
    }
})

$form.Add_DragEnter({
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop) -or $_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::UnicodeText)) {
        $_.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
})

$form.Add_DragDrop({
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        Set-FilePayload -Files ([string[]]$_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop))
        return
    }
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::UnicodeText)) {
        Set-TextPayload -Text ([string]$_.Data.GetData([System.Windows.Forms.DataFormats]::UnicodeText))
    }
})

$form.Add_Shown({
    Read-ClipboardIntoWidget
    Update-ClipboardWatcherStatus
    $script:LastWatchStatusAt = Get-Date
    $timer.Start()
})

$form.Add_FormClosed({
    $timer.Stop()
    if ($script:PayloadImage) { $script:PayloadImage.Dispose() }
    if ($pictureBox.Image) { $pictureBox.Image.Dispose() }
    if ($iconBox.Image) { $iconBox.Image.Dispose() }
    if ($form.Icon) { $form.Icon.Dispose() }
})

Write-WidgetLog "widget_started pid=$PID distro=$Distro ui=winforms-neumorphic"
[void][System.Windows.Forms.Application]::Run($form)
