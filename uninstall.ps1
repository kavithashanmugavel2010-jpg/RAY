# RAY - Universal Package Manager PowerShell Uninstaller
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
#   powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -RemoveFromPath
#   powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -KeepPath
#   powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -CleanCache
#   powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -Force

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$RemoveFromPath = $true,

    [Parameter(Mandatory = $false)]
    [switch]$KeepPath = $false,

    [Parameter(Mandatory = $false)]
    [switch]$CleanCache = $false,

    [Parameter(Mandatory = $false)]
    [string]$InstallDir = "$env:LOCALAPPDATA\ray\bin",

    [Parameter(Mandatory = $false)]
    [switch]$Force = $false,

    [Parameter(Mandatory = $false)]
    [switch]$Help = $false
)

if ($Help) {
    Write-Host "RAY Windows Uninstaller" -ForegroundColor Cyan
    Write-Host "Parameters:"
    Write-Host "  -RemoveFromPath    Remove RAY directory from User PATH (default: `$true)"
    Write-Host "  -KeepPath          Keep RAY directory in User PATH"
    Write-Host "  -CleanCache        Also remove global package cache store (%LOCALAPPDATA%\ray\store)"
    Write-Host "  -InstallDir <path> Installation directory (default: %LOCALAPPDATA%\ray\bin)"
    Write-Host "  -Force             Skip confirmation prompts"
    exit 0
}

if ($KeepPath) {
    $RemoveFromPath = $false
}

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  RAY - Universal Package Manager Uninstaller" -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Are you sure you want to completely uninstall RAY? (Y/n)"
    if ($confirm -and $confirm.Trim().ToLower() -ne "y" -and $confirm.Trim().ToLower() -ne "yes") {
        Write-Host "Uninstallation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# 1. Unregister from Windows Add/Remove Programs
foreach ($keyName in @("RAY", "UPM")) {
    $regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$keyName"
    if (Test-Path $regKey) {
        try {
            Remove-Item -Path $regKey -Recurse -Force
            Write-Host "[RAY] Unregistered $keyName from Windows Settings / Control Panel." -ForegroundColor Green
        } catch {
            Write-Warning "[RAY] Could not remove Windows Settings registry entry: $_"
        }
    }
}

# 2. PATH Configuration
if ($RemoveFromPath) {
    try {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath) {
            $normalizedInstall = $InstallDir.Trim().TrimEnd('\')
            $parts = ($userPath -split ';') | Where-Object {
                $_.Trim() -and ($_.Trim().TrimEnd('\') -ne $normalizedInstall)
            }
            $newPath = $parts -join ';'
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Host "[RAY] Removed '$InstallDir' from User PATH." -ForegroundColor Green
        }

        # Also remove from current PowerShell session PATH
        $currentParts = ($env:Path -split ';') | Where-Object {
            $_.Trim() -and ($_.Trim().TrimEnd('\') -ne $InstallDir.Trim().TrimEnd('\'))
        }
        $env:Path = $currentParts -join ';'
    } catch {
        Write-Warning "[RAY] Failed to clean User PATH: $_"
    }
} else {
    Write-Host "[RAY] Preserved PATH entry for $InstallDir." -ForegroundColor Gray
}

# 3. Clean cache store if requested
if ($CleanCache) {
    foreach ($folder in @("ray", "upm")) {
        $cacheDir = "$env:LOCALAPPDATA\$folder\store"
        $runDir = "$env:LOCALAPPDATA\$folder\run"
        if (Test-Path $cacheDir) {
            Remove-Item -Path $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "[RAY] Removed package cache store: $cacheDir" -ForegroundColor Green
        }
        if (Test-Path $runDir) {
            Remove-Item -Path $runDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "[RAY] Removed ephemeral runtime directory: $runDir" -ForegroundColor Green
        }
    }
}

# 4. Remove binaries
$filesToRemove = @(
    (Join-Path $InstallDir "ray.exe"),
    (Join-Path $InstallDir "ray-uninstaller.exe"),
    (Join-Path $InstallDir "upm.exe"),
    (Join-Path $InstallDir "upm-uninstaller.exe"),
    (Join-Path $InstallDir "uninstall.bat"),
    (Join-Path $InstallDir "uninstall.ps1")
)

foreach ($f in $filesToRemove) {
    if (Test-Path $f) {
        try {
            Remove-Item -Path $f -Force
            Write-Host "[RAY] Deleted: $f" -ForegroundColor Green
        } catch {
            Write-Warning "[RAY] Could not delete $f (file may be in use): $_"
        }
    }
}

# Remove install directory if empty
if (Test-Path $InstallDir) {
    $remaining = Get-ChildItem -Path $InstallDir
    if (-not $remaining) {
        Remove-Item -Path $InstallDir -Force -ErrorAction SilentlyContinue
        Write-Host "[RAY] Removed directory: $InstallDir" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  RAY has been successfully uninstalled!" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""
