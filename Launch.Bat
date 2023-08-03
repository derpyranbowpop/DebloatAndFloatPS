@echo off
set "destination=C:\Temp\DebloatAndFloat\bin"

rem Check if the destination directory exists
if not exist "%destination%" (
    echo Destination directory does not exist. Creating directory...
    mkdir "%destination%"
)

rem Copy files from the "src" directory to the destination
xcopy /S /I /Q /Y /F "src" "%destination%"

rem Change the current directory to the destination
cd /d "%destination%"

rem Check if Launch.bat exists before attempting to run it
if exist "Launch.bat" (
    rem Run the PowerShell script
    powershell.exe ".\Launch.bat"
) else (
    echo "Launch.bat" not found. Aborting script execution.
)
exit