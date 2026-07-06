@echo off
set "DISTRO=%WSL_WECHAT_DISTRO%"
if "%DISTRO%"=="" set "DISTRO=Ubuntu-22.04"
start "" wsl -d "%DISTRO%" -- wechat-desktop

