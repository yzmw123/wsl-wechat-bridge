param(
    [string]$Distro = "Ubuntu-22.04",
    [switch]$NoDesktopShortcut,
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

Get-ChildItem -LiteralPath $windowsSource -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $InstallRoot $_.Name) -Force
}

Get-ChildItem -LiteralPath $launcherSource -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $InstallRoot $_.Name) -Force
}

function ConvertTo-WslPath {
    param([string]$WindowsPath)
    $resolved = (Resolve-Path -LiteralPath $WindowsPath).Path
    $converted = & wsl.exe -d $Distro -- wslpath -u $resolved
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($converted)) {
        throw "Could not convert Windows path to WSL path: $WindowsPath"
    }
    return $converted.Trim()
}

function Quote-Bash {
    param([string]$Value)
    return "'" + ($Value -replace "'", "'\''") + "'"
}

$linuxSourceWsl = ConvertTo-WslPath -WindowsPath $linuxSource
$linuxSourceQuoted = Quote-Bash $linuxSourceWsl

$installCommand = @"
set -e
for file in $linuxSourceQuoted/*; do
  sudo install -m 755 "`$file" /usr/local/bin/
done
"@

& wsl.exe -d $Distro -- bash -lc $installCommand
if ($LASTEXITCODE -ne 0) {
    throw "Failed to install Linux helper commands into distro: $Distro"
}

if (-not $NoDesktopShortcut) {
    $shortcutPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "WSL剪切板同步.lnk"
    $targetPath = Join-Path $env:WINDIR "System32\wscript.exe"
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
if (-not $NoDesktopShortcut) {
    Write-Host "Desktop shortcut: WSL剪切板同步.lnk"
}
