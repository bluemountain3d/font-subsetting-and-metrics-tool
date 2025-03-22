@echo off
set SCRIPT_NAME=subset-fonts-and-metrics-multi.ps1
echo Looking for %SCRIPT_NAME% in current directory...
if exist "%~dp0%SCRIPT_NAME%" (
    echo Found script at: %~dp0%SCRIPT_NAME%
    powershell -ExecutionPolicy Bypass -File "%~dp0%SCRIPT_NAME%"
) else (
    echo ERROR: Could not find %SCRIPT_NAME%
    echo Current directory: %~dp0
    echo Listing files in current directory:
    dir "%~dp0*.ps1"
    echo.
    echo Please make sure the script file exists and has the correct name.
)
pause