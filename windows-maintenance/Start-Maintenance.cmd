@echo off
set "WINDOWS_MAINT_SCRIPT=%~dp0Maintenance.ps1"
if not exist "%WINDOWS_MAINT_SCRIPT%" (
 echo Maintenance.ps1 was not found. Put both files in the same folder.
 pause
 exit /b 1
)
powershell.exe -NoProfile -Command "$a = '-NoProfile -ExecutionPolicy RemoteSigned -NoExit -File ' + [char]34 + $env:WINDOWS_MAINT_SCRIPT + [char]34; Start-Process -FilePath ($PSHOME + '\powershell.exe') -Verb RunAs -ArgumentList $a"
if errorlevel 1 pause
