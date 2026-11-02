@echo off
setlocal EnableDelayedExpansion

title RAY Universal Package Manager Windows Installer
echo ==================================================================
echo   RAY - Universal Package Manager Windows Installer
echo   Engineered ^& Built by Sarvesh.S
echo ==================================================================
echo.

if exist "%~dp0install.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
) else (
    echo [RAY] Local installer script not found. Fetching online installer...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; irm https://raw.githubusercontent.com/kavithashanmugavel2010-jpg/upm/main/install.ps1 | iex"
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Installation failed with exit code %ERRORLEVEL%.
)

echo.
echo ==================================================================
echo   Setup finished. Press any key to exit this window.
echo ==================================================================
pause >nul
