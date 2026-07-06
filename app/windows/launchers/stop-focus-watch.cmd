@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$pidFile = Join-Path '%~dp0' 'focus-watch.pid'; if (Test-Path -LiteralPath $pidFile) { $watchPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1; if ($watchPid -match '^\d+$') { Stop-Process -Id ([int]$watchPid) -Force -ErrorAction SilentlyContinue } }; Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue"
exit /b 0
