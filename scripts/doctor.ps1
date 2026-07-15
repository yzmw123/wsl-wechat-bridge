param(
    [string]$Distro = "Ubuntu-22.04",
    [string]$InstallRoot = "$env:LOCALAPPDATA\WslPrivate\launchers"
)

$ErrorActionPreference = "Continue"
$script:IssueCount = 0
$script:MissingPackages = New-Object System.Collections.Generic.List[string]

function Write-Section {
    param([string]$Name)
    Write-Host ""
    Write-Host "== $Name =="
}

function Write-Check {
    param(
        [string]$Status,
        [string]$Name,
        [string]$Detail = ""
    )

    $line = "[$Status] $Name"
    if (-not [string]::IsNullOrWhiteSpace($Detail)) {
        $line = "$line - $Detail"
    }

    switch ($Status) {
        "ok" { Write-Host $line -ForegroundColor Green }
        "warn" {
            Write-Host $line -ForegroundColor Yellow
            $script:IssueCount++
        }
        "fail" {
            Write-Host $line -ForegroundColor Red
            $script:IssueCount++
        }
        default { Write-Host $line }
    }
}

function Invoke-WslBash {
    param([string]$Command)

    $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Command))
    $runner = "printf '%s' '$encodedCommand' | base64 -d | bash"
    $output = & wsl.exe -d $Distro -- bash -lc $runner 2>$null
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = @($output)
    }
}

function Test-WslCommand {
    param(
        [string]$CommandName,
        [string]$PackageName,
        [switch]$Optional
    )

    $escaped = $CommandName.Replace("'", "'\''")
    $result = Invoke-WslBash -Command "command -v '$escaped'"
    if ($result.ExitCode -eq 0 -and $result.Output.Count -gt 0) {
        Write-Check "ok" "linux command: $CommandName" ($result.Output[0])
        return
    }

    if ($Optional) {
        Write-Check "warn" "optional linux command missing: $CommandName" "package: $PackageName"
    }
    else {
        Write-Check "fail" "linux command missing: $CommandName" "package: $PackageName"
    }

    if (-not [string]::IsNullOrWhiteSpace($PackageName)) {
        $script:MissingPackages.Add($PackageName)
    }
}

function Test-WslPackage {
    param(
        [string]$PackageName,
        [switch]$Optional
    )

    $escaped = $PackageName.Replace("'", "'\''")
    $result = Invoke-WslBash -Command "dpkg -s '$escaped' 2>/dev/null | grep -q '^Status: install ok installed$'"
    if ($result.ExitCode -eq 0) {
        Write-Check "ok" "linux package: $PackageName"
        return
    }

    if ($Optional) {
        Write-Check "warn" "optional linux package missing: $PackageName"
    }
    else {
        Write-Check "fail" "linux package missing: $PackageName"
    }
    $script:MissingPackages.Add($PackageName)
}

Write-Host "WSL WeChat Bridge doctor"
Write-Host "Distro: $Distro"
Write-Host "InstallRoot: $InstallRoot"

Write-Section "Windows"
if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    Write-Check "ok" "wsl.exe" ((Get-Command wsl.exe).Source)
}
else {
    Write-Check "fail" "wsl.exe" "Install WSL first."
    exit 1
}

if (Get-Command powershell.exe -ErrorAction SilentlyContinue) {
    Write-Check "ok" "powershell.exe" ((Get-Command powershell.exe).Source)
}
else {
    Write-Check "fail" "powershell.exe"
}

if (Get-Command wscript.exe -ErrorAction SilentlyContinue) {
    Write-Check "ok" "wscript.exe" ((Get-Command wscript.exe).Source)
}
else {
    Write-Check "fail" "wscript.exe" "Windows helper launchers need it."
}

Write-Section "WSL distro"
$probe = Invoke-WslBash -Command "printf '%s' ok"
if ($probe.ExitCode -eq 0 -and (($probe.Output -join "") -match "ok")) {
    Write-Check "ok" "distro starts" $Distro
}
else {
    Write-Check "fail" "distro starts" (($probe.Output -join " ") -replace "\s+", " ")
    exit 1
}

$kernelProbe = Invoke-WslBash -Command "uname -r"
if ($kernelProbe.ExitCode -eq 0 -and $kernelProbe.Output.Count -gt 0) {
    $kernel = [string]$kernelProbe.Output[0]
    if ($kernel -match "WSL2|microsoft-standard") {
        Write-Check "ok" "WSL kernel" $kernel
    }
    else {
        Write-Check "warn" "WSL kernel" "Expected WSL2-style kernel, got: $kernel"
    }
}

Write-Section "Windows helper files"
$requiredWindowsFiles = @(
    "clipboard-widget.ps1",
    "clipboard-watch.ps1",
    "focus-watch.ps1",
    "notice.ps1",
    "start-clipboard-widget-hidden.vbs",
    "start-clipboard-watch-hidden.vbs",
    "start-focus-watch-hidden.vbs",
    "stop-clipboard-watch.cmd",
    "wsl-clip-cube.ico"
)

foreach ($file in $requiredWindowsFiles) {
    $path = Join-Path $InstallRoot $file
    if (Test-Path -LiteralPath $path) {
        Write-Check "ok" "windows helper: $file"
    }
    else {
        Write-Check "fail" "windows helper missing: $file" $path
    }
}

Write-Section "Linux helper commands"
$requiredHelpers = @(
    "wechat-desktop",
    "wechat-desktop-status",
    "wechat-desktop-stop",
    "wechat-restore",
    "winclip2wechat",
    "wechatclip2win",
    "wsl-app-notify-bridge",
    "wsl-app-notify-bridge-restart",
    "wsl-app-notification-daemon",
    "wsl-app-badge-notify-watch",
    "wsl-app-focus-bridge",
    "wsl-focus-sink"
)

foreach ($helper in $requiredHelpers) {
    Test-WslCommand -CommandName $helper -PackageName "project installer"
}

Write-Section "Runtime defaults"
$statusProbe = Invoke-WslBash -Command "wechat-desktop-status 2>/dev/null | grep -E '^(notice_bridge_enabled|focus_watch_enabled|clipboard_watch_enabled|badge_watch_enabled|log_max_bytes|log_backups|clipboard_ttl_seconds)='"
if ($statusProbe.ExitCode -eq 0 -and $statusProbe.Output.Count -gt 0) {
    foreach ($line in $statusProbe.Output) {
        Write-Check "ok" "runtime setting" $line
    }
}
else {
    Write-Check "warn" "runtime settings unavailable" "Run wechat-desktop-status inside WSL for details."
}

Write-Section "Linux dependencies"
$dependencies = @(
    @{ Command = "xdpyinfo"; Package = "x11-utils" },
    @{ Command = "xprop"; Package = "x11-utils" },
    @{ Command = "xmessage"; Package = "x11-utils" },
    @{ Command = "xwd"; Package = "x11-apps" },
    @{ Command = "Xephyr"; Package = "xserver-xephyr" },
    @{ Command = "openbox"; Package = "openbox" },
    @{ Command = "xclip"; Package = "xclip" },
    @{ Command = "wmctrl"; Package = "wmctrl" },
    @{ Command = "xdotool"; Package = "xdotool" },
    @{ Command = "dbus-launch"; Package = "dbus-x11" },
    @{ Command = "fcitx5"; Package = "fcitx5" },
    @{ Command = "python3"; Package = "python3" },
    @{ Command = "sha256sum"; Package = "coreutils" }
)

foreach ($dep in $dependencies) {
    Test-WslCommand -CommandName $dep.Command -PackageName $dep.Package
}
Test-WslCommand -CommandName "tint2" -PackageName "tint2" -Optional

Write-Section "Chinese input method"
Test-WslPackage -PackageName "fcitx5"
Test-WslPackage -PackageName "fcitx5-chinese-addons"
Test-WslPackage -PackageName "fcitx5-pinyin"
Write-Check "ok" "wechat-desktop input env" "Starts fcitx5 and exports XMODIFIERS/GTK_IM_MODULE/QT_IM_MODULE."

Write-Section "Python modules"
$pythonModules = @(
    @{ Module = "dbus"; Package = "python3-dbus" },
    @{ Module = "gi"; Package = "python3-gi" }
)

foreach ($module in $pythonModules) {
    $moduleName = $module.Module
    $modulePackage = $module.Package
    $moduleCheck = Invoke-WslBash -Command "python3 -c 'import $moduleName'"
    if ($moduleCheck.ExitCode -eq 0) {
        Write-Check "ok" "python module: $moduleName"
    }
    else {
        Write-Check "fail" "python module missing: $moduleName" "package: $modulePackage"
        $script:MissingPackages.Add($modulePackage)
    }
}

Write-Section "Linux WeChat"
$wechatConfig = Invoke-WslBash -Command "sed -n 's/^WECHAT_COMMAND=//p' ~/.config/wsl-wechat-bridge/config 2>/dev/null | head -n1"
$wechatCommand = ""
if ($wechatConfig.ExitCode -eq 0 -and $wechatConfig.Output.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($wechatConfig.Output[0])) {
    $wechatCommand = ([string]$wechatConfig.Output[0]).Trim().Trim("'").Trim('"')
}
else {
    $wechatProbe = Invoke-WslBash -Command "command -v wechat || { test -x /usr/bin/wechat && printf '%s\n' /usr/bin/wechat; }"
    if ($wechatProbe.ExitCode -eq 0 -and $wechatProbe.Output.Count -gt 0) {
        $wechatCommand = [string]$wechatProbe.Output[0]
    }
}

if (-not [string]::IsNullOrWhiteSpace($wechatCommand)) {
    Write-Check "ok" "Linux WeChat command" $wechatCommand
}
else {
    Write-Check "fail" "Linux WeChat command" "Install official Linux WeChat or set WECHAT_COMMAND."
}

Write-Section "Windows files from Linux"
$mountProbe = Invoke-WslBash -Command "test -d /mnt/c"
if ($mountProbe.ExitCode -eq 0) {
    Write-Check "ok" "Windows drive mounted" "/mnt/c"
}
else {
    Write-Check "fail" "Windows drive mount missing" "/mnt/c"
}

$linkNames = @("Windows-C", "Windows-D", "Windows-Desktop", "Windows-Downloads", "Windows-Documents")
$foundFileLink = $false
foreach ($linkName in $linkNames) {
    $linkProbe = Invoke-WslBash -Command "test -L ~/$linkName && readlink ~/$linkName"
    if ($linkProbe.ExitCode -eq 0 -and $linkProbe.Output.Count -gt 0) {
        $foundFileLink = $true
        Write-Check "ok" "Windows file link" "~/$linkName -> $($linkProbe.Output[0])"
    }
}

if (-not $foundFileLink) {
    Write-Check "warn" "Windows file links missing" "Run scripts/install.ps1 again, or create ~/Windows-C style links."
}

Write-Section "Summary"
if ($script:MissingPackages.Count -gt 0) {
    $packages = $script:MissingPackages | Sort-Object -Unique
    Write-Host "Suggested Ubuntu dependency install command:"
    Write-Host "wsl -d $Distro -- sudo apt-get update"
    Write-Host "wsl -d $Distro -- sudo apt-get install -y $($packages -join ' ')"
}

if ($script:IssueCount -eq 0) {
    Write-Check "ok" "doctor result" "No issues found."
    exit 0
}

Write-Check "warn" "doctor result" "$script:IssueCount issue(s) found."
exit 1
