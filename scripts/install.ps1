param(
    [string]$Distro = "Ubuntu-22.04",
    [switch]$NoDesktopShortcut,
    [switch]$InstallDependencies,
    [switch]$NoWindowsFileLinks,
    [switch]$NoDoctor,
    [string]$InstallRoot = "$env:LOCALAPPDATA\WslPrivate\launchers"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$windowsSource = Join-Path $repoRoot "app\windows"
$launcherSource = Join-Path $windowsSource "launchers"
$linuxSource = Join-Path $repoRoot "app\linux\bin"

if (-not (Test-Path -LiteralPath $windowsSource)) {
    throw "Windows source directory not found: $windowsSource"
}
if (-not (Test-Path -LiteralPath $linuxSource)) {
    throw "Linux source directory not found: $linuxSource"
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null

Get-ChildItem -LiteralPath $windowsSource -File -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $InstallRoot $_.Name) -Force
}

Get-ChildItem -LiteralPath $launcherSource -File -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $InstallRoot $_.Name) -Force
}

function ConvertTo-WslPath {
    param([string]$WindowsPath)
    $resolved = (Resolve-Path -LiteralPath $WindowsPath).Path
    $converted = & wsl.exe -d $Distro --exec wslpath -u $resolved
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($converted)) {
        throw "Could not convert Windows path to WSL path: $WindowsPath"
    }
    return $converted.Trim()
}

function Quote-Bash {
    param([string]$Value)
    return "'" + ($Value -replace "'", "'\''") + "'"
}

function Invoke-WslBash {
    param(
        [string]$Script,
        [string]$ErrorMessage
    )

    $encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Script))
    $runner = "printf '%s' '$encodedScript' | base64 -d | bash"
    & wsl.exe -d $Distro -- bash -lc $runner
    if ($LASTEXITCODE -ne 0) {
        throw $ErrorMessage
    }
}

if ($InstallDependencies) {
    $dependencyPackages = @(
        "x11-utils",
        "x11-apps",
        "xclip",
        "wmctrl",
        "xdotool",
        "xserver-xephyr",
        "openbox",
        "tint2",
        "dbus-x11",
        "fcitx5",
        "fcitx5-chinese-addons",
        "fcitx5-pinyin",
        "python3",
        "python3-dbus",
        "python3-gi"
    )
    $dependencyArgs = ($dependencyPackages | ForEach-Object { Quote-Bash $_ }) -join " "
    $dependencyCommand = @"
set -e
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y $dependencyArgs
"@
    Invoke-WslBash -Script $dependencyCommand -ErrorMessage "Failed to install Linux dependencies into distro: $Distro"
}

$linuxSourceWsl = ConvertTo-WslPath -WindowsPath $linuxSource
$linuxSourceQuoted = Quote-Bash $linuxSourceWsl

$installCommand = @"
set -e
for file in $linuxSourceQuoted/*; do
  [ -f "`$file" ] || continue
  sudo install -m 755 "`$file" /usr/local/bin/
done
"@

Invoke-WslBash -Script $installCommand -ErrorMessage "Failed to install Linux helper commands into distro: $Distro"

if (-not $NoWindowsFileLinks) {
    $linkCommand = @'
set -e

make_link() {
  target="$1"
  name="$2"
  link="$HOME/$name"

  [ -e "$target" ] || return 0

  if [ -L "$link" ] || [ ! -e "$link" ]; then
    ln -sfn "$target" "$link"
    printf 'link=%s -> %s\n' "$link" "$target"
  else
    printf 'skip_existing=%s\n' "$link"
  fi
}

for drive in /mnt/[a-z]; do
  [ -d "$drive" ] || continue
  letter="$(basename "$drive" | tr '[:lower:]' '[:upper:]')"
  make_link "$drive" "Windows-$letter"
done

win_profile="$(cmd.exe /C echo %USERPROFILE% 2>/dev/null | tr -d '\r' || true)"
if [ -n "$win_profile" ] && [[ "$win_profile" != *%* ]]; then
  profile_path="$(wslpath -u "$win_profile" 2>/dev/null || true)"
  if [ -n "$profile_path" ]; then
    make_link "$profile_path/Desktop" "Windows-Desktop"
    make_link "$profile_path/Downloads" "Windows-Downloads"
    make_link "$profile_path/Documents" "Windows-Documents"
  fi
fi
'@

    Invoke-WslBash -Script $linkCommand -ErrorMessage "Failed to create Windows file links in distro: $Distro"
}

if (-not $NoDesktopShortcut) {
    $shortcutPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "WSL剪切板同步.lnk"
    $windowsDir = $env:WINDIR
    if ([string]::IsNullOrWhiteSpace($windowsDir)) {
        $windowsDir = $env:SystemRoot
    }
    if ([string]::IsNullOrWhiteSpace($windowsDir)) {
        $windowsDir = "C:\Windows"
    }
    $targetPath = Join-Path $windowsDir "System32\wscript.exe"
    $widgetLauncher = Join-Path $InstallRoot "start-clipboard-widget-hidden.vbs"
    $iconPath = Join-Path $InstallRoot "wsl-clip-cube.ico"

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $targetPath
    $shortcut.Arguments = "//B `"$widgetLauncher`""
    $shortcut.WorkingDirectory = $InstallRoot
    $shortcut.IconLocation = "$iconPath,0"
    $shortcut.Save()
}

Write-Host "Installed WSL WeChat Bridge for distro: $Distro"
Write-Host "Windows helpers: $InstallRoot"
Write-Host "Linux commands: /usr/local/bin"
if (-not $NoWindowsFileLinks) {
    Write-Host "Windows file links: ~/Windows-C, ~/Windows-D, ~/Windows-Downloads, ..."
}
if (-not $NoDesktopShortcut) {
    Write-Host "Desktop shortcut: WSL剪切板同步.lnk"
}

if (-not $NoDoctor) {
    $doctorScript = Join-Path $PSScriptRoot "doctor.ps1"
    if (Test-Path -LiteralPath $doctorScript) {
        Write-Host ""
        Write-Host "Running doctor checks..."
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $doctorScript -Distro $Distro -InstallRoot $InstallRoot
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Doctor checks reported issues. Review the output above."
        }
    }
}
