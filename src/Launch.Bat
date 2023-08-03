@echo off
rem # ELEVATE TO ADMIN #
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )

rem Launch Debloat And Float
PowerShell.exe -ExecutionPolicy Bypass -File .\DebloatAndFloat.ps1

rem Create a Delete.bat file untill i can figgure out auto delete
xcopy /Y "delete.bat" %USERPROFILE%\Desktop
Exit