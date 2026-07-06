@echo off
set "DISTRO=%WSL_WECHAT_DISTRO%"
if "%DISTRO%"=="" set "DISTRO=Ubuntu-22.04"
wsl -d "%DISTRO%" -- winclip2wechat --paste

