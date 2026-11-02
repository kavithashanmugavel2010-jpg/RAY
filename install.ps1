# RAY - Universal Package Manager PowerShell Installer
# Engineered & Built by Sarvesh.S
# Repository: https://github.com/kavithashanmugavel2010-jpg/RAY.git

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [bool]$AddToPath = $true,

    [Parameter(Mandatory = $false)]
    [switch]$NoPath = $false,

    [Parameter(Mandatory = $false)]
    [string]$InstallDir = "$env:LOCALAPPDATA\ray\bin",

    [Parameter(Mandatory = $false)]
    [string]$BinaryPath = "",

    [Parameter(Mandatory = $false)]
    [switch]$NoPause = $false,

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
    Write-Host "  -NoPause           Do not pause upon completion"
    exit 0
}

if ($NoPath) {
    $AddToPath = $false
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  RAY - Universal Package Manager Windows Installer" -ForegroundColor White
Write-Host "  Engineered & Built by Sarvesh.S" -ForegroundColor Gray
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# Safely determine script directory (handles both local script execution and irm | iex)
$scriptDir = $null
try {
    if ($MyInvocation -and $MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
} catch {
    $scriptDir = $null
}
if (-not $scriptDir) {
    $scriptDir = $PWD.Path
}

$repoUrls = @(
    "https://github.com/kavithashanmugavel2010-jpg/RAY/raw/main",
    "https://github.com/kavithashanmugavel2010-jpg/upm/raw/main"
)

# 1. Prepare destination directory
try {
    if (-not (Test-Path $InstallDir)) {
        Write-Host "[RAY] Creating installation directory: $InstallDir" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
} catch {
    Write-Error "[RAY] Failed to create installation directory '$InstallDir': $_"
    if (-not $NoPause) { Read-Host "Press Enter to exit..." }
    exit 1
}

$destExe = Join-Path $InstallDir "ray.exe"
$destUninstaller = Join-Path $InstallDir "ray-uninstaller.exe"
$destSetup = Join-Path $InstallDir "ray-setup.exe"

# 2. Locate local ray.exe or download directly from GitHub
$installedRay = $false

if ($BinaryPath -and (Test-Path $BinaryPath)) {
    try {
        Copy-Item -Path (Resolve-Path $BinaryPath).Path -Destination $destExe -Force
        $installedRay = $true
        Write-Host "[RAY] Installed ray.exe from local path: $BinaryPath" -ForegroundColor Green
    } catch {
        Write-Warning "[RAY] Failed to copy binary from '$BinaryPath': $_"
    }
}

if (-not $installedRay) {
    $localCandidates = @(
        (Join-Path $scriptDir "ray.exe"),
        (Join-Path $scriptDir "dist\ray.exe"),
        (Join-Path $scriptDir "target\release\ray.exe"),
        (Join-Path $scriptDir "target\debug\ray.exe")
    )

    foreach ($cand in $localCandidates) {
        if ($cand -and (Test-Path $cand)) {
            try {
                Copy-Item -Path $cand -Destination $destExe -Force
                $installedRay = $true
                Write-Host "[RAY] Installed ray.exe from local candidate: $cand" -ForegroundColor Green
                break
            } catch {
                # Continue checking other candidates
            }
        }
    }
}

# If not found locally, download atomically to temp file then place in destination
if (-not $installedRay) {
    Write-Host "[RAY] Downloading ray.exe from GitHub repository..." -ForegroundColor Yellow
    $tempFile = Join-Path $env:TEMP "ray_$([Guid]::NewGuid().ToString('N')).exe"

    foreach ($baseUrl in $repoUrls) {
        $rayDownloadUrl = "$baseUrl/dist/ray.exe"
        try {
            Invoke-WebRequest -Uri $rayDownloadUrl -OutFile $tempFile -UseBasicParsing
            if ((Test-Path $tempFile) -and ((Get-Item $tempFile).Length -gt 100000)) {
                Stop-Process -Name "ray" -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 150
                Move-Item -Path $tempFile -Destination $destExe -Force
                $installedRay = $true
                Write-Host "[RAY] Downloaded and installed ray.exe successfully!" -ForegroundColor Green
                break
            }
        } catch {
            # Try next URL
        }
    }

    if (-not $installedRay) {
        # Fallback: try downloading ray-setup.exe which contains embedded ray.exe
        foreach ($baseUrl in $repoUrls) {
            $setupUrl = "$baseUrl/dist/ray-setup.exe"
            try {
                $tempSetup = Join-Path $env:TEMP "ray_setup_$([Guid]::NewGuid().ToString('N')).exe"
                Invoke-WebRequest -Uri $setupUrl -OutFile $tempSetup -UseBasicParsing
                if ((Test-Path $tempSetup) -and ((Get-Item $tempSetup).Length -gt 1000000)) {
                    Write-Host "[RAY] Extracting from ray-setup.exe..." -ForegroundColor Cyan
                    & $tempSetup -y
                    if (Test-Path $destExe) {
                        $installedRay = $true
                        Remove-Item -Path $tempSetup -Force -ErrorAction SilentlyContinue
                        break
                    }
                }
            } catch {}
        }
    }

    if (-not $installedRay) {
        Write-Error "[RAY] Could not install ray.exe. Please download ray-setup.exe directly from: https://github.com/kavithashanmugavel2010-jpg/RAY/raw/main/dist/ray-setup.exe"
        if (-not $NoPause) { Read-Host "Press Enter to exit..." }
        exit 1
    }
}

# Keep upm.exe alias in bin directory for backward compatibility
try {
    $destLegacyExe = Join-Path $InstallDir "upm.exe"
    Copy-Item -Path $destExe -Destination $destLegacyExe -Force
} catch {}

# 3. Locate or download ray-uninstaller.exe
$installedUninstaller = $false
$localUninstallerCandidates = @(
    (Join-Path $scriptDir "ray-uninstaller.exe"),
    (Join-Path $scriptDir "dist\ray-uninstaller.exe"),
    (Join-Path $scriptDir "target\release\ray-uninstaller.exe")
)
foreach ($uCand in $localUninstallerCandidates) {
    if ($uCand -and (Test-Path $uCand)) {
        try {
            Copy-Item -Path $uCand -Destination $destUninstaller -Force
            $installedUninstaller = $true
            break
        } catch {}
    }
}
if (-not $installedUninstaller) {
    $tempUFile = Join-Path $env:TEMP "ray_uninstaller_$([Guid]::NewGuid().ToString('N')).exe"
    foreach ($baseUrl in $repoUrls) {
        try {
            $uninstallerUrl = "$baseUrl/dist/ray-uninstaller.exe"
            Invoke-WebRequest -Uri $uninstallerUrl -OutFile $tempUFile -UseBasicParsing
            if ((Test-Path $tempUFile) -and ((Get-Item $tempUFile).Length -gt 50000)) {
                Move-Item -Path $tempUFile -Destination $destUninstaller -Force
                $installedUninstaller = $true
                Write-Host "[RAY] Installed ray-uninstaller.exe" -ForegroundColor Green
                break
            }
        } catch {}
    }
}

# 4. Locate or download ray-setup.exe (GUI Installer)
$installedSetup = $false
$localSetupCandidates = @(
    (Join-Path $scriptDir "ray-setup.exe"),
    (Join-Path $scriptDir "dist\ray-setup.exe"),
    (Join-Path $scriptDir "target\release\ray-setup.exe")
)
foreach ($sCand in $localSetupCandidates) {
    if ($sCand -and (Test-Path $sCand)) {
        try {
            Copy-Item -Path $sCand -Destination $destSetup -Force
            $installedSetup = $true
            break
        } catch {}
    }
}
if (-not $installedSetup) {
    $tempSFile = Join-Path $env:TEMP "ray_setup_$([Guid]::NewGuid().ToString('N')).exe"
    foreach ($baseUrl in $repoUrls) {
        try {
            $setupUrl = "$baseUrl/dist/ray-setup.exe"
            Invoke-WebRequest -Uri $setupUrl -OutFile $tempSFile -UseBasicParsing
            if ((Test-Path $tempSFile) -and ((Get-Item $tempSFile).Length -gt 500000)) {
                Move-Item -Path $tempSFile -Destination $destSetup -Force
                $installedSetup = $true
                break
            }
        } catch {}
    }
}

# 5. Copy uninstall scripts
if (Test-Path (Join-Path $scriptDir "uninstall.bat")) {
    try { Copy-Item -Path (Join-Path $scriptDir "uninstall.bat") -Destination (Join-Path $InstallDir "uninstall.bat") -Force } catch {}
}
if (Test-Path (Join-Path $scriptDir "uninstall.ps1")) {
    try { Copy-Item -Path (Join-Path $scriptDir "uninstall.ps1") -Destination (Join-Path $InstallDir "uninstall.ps1") -Force } catch {}
}

# 6. Register in Windows Installed Apps (Settings / Control Panel)
try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\RAY"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "DisplayName" -Value "RAY - Universal Package Manager" -Force
    Set-ItemProperty -Path $regPath -Name "DisplayVersion" -Value "0.1.0" -Force
    Set-ItemProperty -Path $regPath -Name "Publisher" -Value "Sarvesh.S" -Force
    Set-ItemProperty -Path $regPath -Name "InstallLocation" -Value $InstallDir -Force
    if (Test-Path $destUninstaller) {
        Set-ItemProperty -Path $regPath -Name "UninstallString" -Value "`"$destUninstaller`"" -Force
        Set-ItemProperty -Path $regPath -Name "QuietUninstallString" -Value "`"$destUninstaller`" -y" -Force
    } else {
        Set-ItemProperty -Path $regPath -Name "UninstallString" -Value "`"$destExe`" self-uninstall" -Force
        Set-ItemProperty -Path $regPath -Name "QuietUninstallString" -Value "`"$destExe`" self-uninstall -y" -Force
    }
    Set-ItemProperty -Path $regPath -Name "DisplayIcon" -Value $destExe -Force
    Write-Host "[RAY] Registered in Windows Settings (Installed Apps)" -ForegroundColor Green
} catch {
    Write-Warning "[RAY] Could not register in Windows Settings: $_"
}

# 7. Configure User PATH
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

        # Also update current session PATH
        if (($env:Path -split ';') -notcontains $InstallDir) {
            $env:Path = "$InstallDir;$env:Path"
        }
    } catch {
        Write-Warning "[RAY] Could not update User PATH automatically: $_"
    }
} else {
    Write-Host "[RAY] Skipped adding to PATH as requested." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Installation Complete! Executing 'ray version'..." -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

try {
    & $destExe version
} catch {
    Write-Warning "[RAY] Could not execute $destExe version: $_"
}

Write-Host ""
Write-Host "Thanks for choosing RAY! Built by Sarvesh.S" -ForegroundColor Green
Write-Host ""

# Prevent console from exiting automatically if run in an interactive window
if (-not $NoPause) {
    if ($Host.Name -eq "ConsoleHost" -and (-not $env:CI)) {
        Write-Host "Press Enter to finish..." -ForegroundColor Gray
        Read-Host | Out-Null
    }
}
