@echo off
set "DISTRO=%WSL_WECHAT_DISTRO%"
if "%DISTRO%"=="" set "DISTRO=Ubuntu-22.04"
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0clipboard-widget.ps1" -Distro "%DISTRO%"
