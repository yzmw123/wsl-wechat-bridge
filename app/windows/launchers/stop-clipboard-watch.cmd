@echo off
set "PIDFILE=%~dp0clipboard-watch.pid"
if not exist "%PIDFILE%" (
  echo clipboard watcher is not running
  exit /b 0
)
set /p PID=<"%PIDFILE%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Stop-Process -Id %PID% -Force -ErrorAction SilentlyContinue"
del "%PIDFILE%" >nul 2>nul
echo clipboard watcher stopped

