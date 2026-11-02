@echo off
setlocal EnableDelayedExpansion

title RAY Universal Package Manager Uninstaller
echo ==================================================================
echo   RAY - Universal Package Manager Windows Uninstaller
echo   Engineered ^& Built by Sarvesh.S
echo ==================================================================
echo.

if exist "%~dp0uninstall.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
) else (
    echo [RAY] Local uninstaller script not found. Running self-uninstall...
    "%~dp0ray.exe" self-uninstall %*
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] RAY Uninstallation encountered an error (Code: %ERRORLEVEL%).
)

echo.
echo ==================================================================
echo   Uninstallation complete. Press any key to exit this window.
echo ==================================================================
pause >nul
