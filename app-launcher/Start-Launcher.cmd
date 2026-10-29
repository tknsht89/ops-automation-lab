@echo off
setlocal
set "APP_LAUNCHER_DIR=%~dp0"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create([System.IO.File]::ReadAllText((Join-Path $env:APP_LAUNCHER_DIR 'AppLauncher.ps1'), [System.Text.Encoding]::UTF8)))"
if errorlevel 1 pause
endlocal
