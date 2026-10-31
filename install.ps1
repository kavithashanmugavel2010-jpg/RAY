# RAY - Universal Package Manager PowerShell Installer
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -AddToPath
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -AddToPath:$false
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -InstallDir "C:\MyTools\ray"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$AddToPath = $true,

    [Parameter(Mandatory = $false)]
    [switch]$NoPath = $false,

    [Parameter(Mandatory = $false)]
    [string]$InstallDir = "$env:LOCALAPPDATA\ray\bin",

    [Parameter(Mandatory = $false)]
    [string]$BinaryPath = "",

    [Parameter(Mandatory = $false)]
    [switch]$Help = $false
)

if ($Help) {
    Write-Host "RAY Windows Installer" -ForegroundColor Cyan
    Write-Host "Parameters:"
    Write-Host "  -AddToPath         Add RAY to User PATH (default: `$true)"
    Write-Host "  -NoPath            Do not add RAY to User PATH"
    Write-Host "  -InstallDir <path> Custom installation directory (default: %LOCALAPPDATA%\ray\bin)"
    Write-Host "  -BinaryPath <path> Specific path to ray.exe to install"
    exit 0
}

if ($NoPath) {
    $AddToPath = $false
}

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  RAY - Universal Package Manager Installer (Native Win32)" -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Locate or build ray.exe
$targetExe = ""
if ($BinaryPath -and (Test-Path $BinaryPath)) {
    $targetExe = (Resolve-Path $BinaryPath).Path
} else {
    $candidates = @(
        (Join-Path $scriptDir "ray.exe"),
        (Join-Path $scriptDir "target\release\ray.exe"),
        (Join-Path $scriptDir "target\debug\ray.exe"),
        (Join-Path $scriptDir "upm.exe"),
        (Join-Path $scriptDir "target\release\upm.exe"),
        (Join-Path $scriptDir "target\debug\upm.exe")
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            $targetExe = $cand
            break
        }
    }
}

if (-not $targetExe) {
    if (Test-Path (Join-Path $scriptDir "Cargo.toml")) {
        Write-Host "[RAY] ray.exe not found. Building release binary via 'cargo build --release'..." -ForegroundColor Yellow
        $prevPwd = Get-Location
        Set-Location $scriptDir
        & cargo build --release
        Set-Location $prevPwd
        $relPath = Join-Path $scriptDir "target\release\ray.exe"
        if (Test-Path $relPath) {
            $targetExe = $relPath
        } else {
            Write-Error "[RAY] Failed to find compiled binary at $relPath."
            exit 1
        }
    } else {
        Write-Host "[RAY] Local binary not found. Downloading ray-setup.exe from GitHub..." -ForegroundColor Cyan
        $downloadUrl = "https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-setup.exe"
        $tempSetup = Join-Path $env:TEMP "ray-setup.exe"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $tempSetup -UseBasicParsing
        } catch {
            $downloadUrl = "https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/upm-setup.exe"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $tempSetup -UseBasicParsing
        }
        if (Test-Path $tempSetup) {
            Write-Host "[RAY] Running setup installer..." -ForegroundColor Green
            & $tempSetup -y
            exit 0
        } else {
            Write-Error "[RAY] Failed to download setup installer from GitHub."
            exit 1
        }
    }
}

Write-Host "[RAY] Source executable: $targetExe" -ForegroundColor Gray

# 2. Prepare destination directory
if (-not (Test-Path $InstallDir)) {
    Write-Host "[RAY] Creating directory: $InstallDir" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$destExe = Join-Path $InstallDir "ray.exe"

# 3. Copy binary
try {
    Copy-Item -Path $targetExe -Destination $destExe -Force
    Write-Host "[RAY] Installed ray.exe to: $destExe" -ForegroundColor Green

    # Also keep upm.exe alias in bin directory for backward compatibility
    $destLegacyExe = Join-Path $InstallDir "upm.exe"
    Copy-Item -Path $targetExe -Destination $destLegacyExe -Force

    # Copy ray-uninstaller.exe if found
    $uninstallerCandidates = @(
        (Join-Path $scriptDir "ray-uninstaller.exe"),
        (Join-Path $scriptDir "target\release\ray-uninstaller.exe"),
        (Join-Path $scriptDir "target\debug\ray-uninstaller.exe"),
        (Join-Path $scriptDir "upm-uninstaller.exe"),
        (Join-Path $scriptDir "target\release\upm-uninstaller.exe"),
        (Join-Path $scriptDir "target\debug\upm-uninstaller.exe")
    )
    foreach ($cand in $uninstallerCandidates) {
        if (Test-Path $cand) {
            $destUninstaller = Join-Path $InstallDir "ray-uninstaller.exe"
            Copy-Item -Path $cand -Destination $destUninstaller -Force
            Write-Host "[RAY] Installed ray-uninstaller.exe to: $destUninstaller" -ForegroundColor Green
            break
        }
    }

    # Copy uninstall scripts
    if (Test-Path (Join-Path $scriptDir "uninstall.bat")) {
        Copy-Item -Path (Join-Path $scriptDir "uninstall.bat") -Destination (Join-Path $InstallDir "uninstall.bat") -Force
    }
    if (Test-Path (Join-Path $scriptDir "uninstall.ps1")) {
        Copy-Item -Path (Join-Path $scriptDir "uninstall.ps1") -Destination (Join-Path $InstallDir "uninstall.ps1") -Force
    }

    # Register in Windows Installed Apps (Settings / Control Panel)
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\RAY"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "DisplayName" -Value "RAY - Universal Package Manager" -Force
    Set-ItemProperty -Path $regPath -Name "DisplayVersion" -Value "0.1.0" -Force
    Set-ItemProperty -Path $regPath -Name "Publisher" -Value "Sarvesh.S" -Force
    Set-ItemProperty -Path $regPath -Name "InstallLocation" -Value $InstallDir -Force
    $uninstallerExe = Join-Path $InstallDir "ray-uninstaller.exe"
    if (Test-Path $uninstallerExe) {
        Set-ItemProperty -Path $regPath -Name "UninstallString" -Value "`"$uninstallerExe`"" -Force
        Set-ItemProperty -Path $regPath -Name "QuietUninstallString" -Value "`"$uninstallerExe`" -y" -Force
    } else {
        Set-ItemProperty -Path $regPath -Name "UninstallString" -Value "`"$destExe`" self-uninstall" -Force
        Set-ItemProperty -Path $regPath -Name "QuietUninstallString" -Value "`"$destExe`" self-uninstall -y" -Force
    }
    Set-ItemProperty -Path $regPath -Name "DisplayIcon" -Value $destExe -Force
    Write-Host "[RAY] Registered in Windows Installed Apps (Settings / Control Panel)" -ForegroundColor Green
} catch {
    Write-Error "[RAY] Failed to copy ray.exe to $destExe : $_"
    exit 1
}

# 4. PATH Configuration
if ($AddToPath) {
    try {
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if (-not $userPath) {
            $userPath = ""
        }

        $normalizedDirs = ($userPath -split ';') | ForEach-Object { $_.Trim().TrimEnd('\') }
        $normalizedInstall = $InstallDir.Trim().TrimEnd('\')

        $alreadyInPath = $normalizedDirs -contains $normalizedInstall

        if ($alreadyInPath) {
            Write-Host "[RAY] Directory already present in User PATH: $InstallDir" -ForegroundColor DarkGray
        } else {
            $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) {
                $InstallDir
            } elseif ($userPath.EndsWith(';')) {
                "$userPath$InstallDir"
            } else {
                "$userPath;$InstallDir"
            }

            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Host "[RAY] Successfully added '$InstallDir' to User PATH!" -ForegroundColor Green
        }

        # Also update current PowerShell process session PATH
        if (($env:Path -split ';') -notcontains $InstallDir) {
            $env:Path = "$InstallDir;$env:Path"
        }
    } catch {
        Write-Warning "[RAY] Could not update User PATH automatically: $_"
    }
} else {
    Write-Host "[RAY] Skipped adding to PATH as requested (-AddToPath:`$false or -NoPath)." -ForegroundColor Yellow
    Write-Host "      To use 'ray' globally, manually add '$InstallDir' to your PATH." -ForegroundColor Gray
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Installation Complete! Running 'ray version'..." -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

& $destExe version

Write-Host ""
Write-Host "Thanks for choosing RAY! Built by Sarvesh.S" -ForegroundColor Green
Write-Host ""
