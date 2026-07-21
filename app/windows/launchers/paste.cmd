@echo off
set "DISTRO=%WSL_WECHAT_DISTRO%"
if not defined DISTRO if exist "%~dp0distro.txt" set /p "DISTRO="<"%~dp0distro.txt"
if "%DISTRO%"=="" set "DISTRO=Ubuntu-22.04"
wsl -d "%DISTRO%" -- winclip2wechat --paste

