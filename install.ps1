# RAY - Universal Package Manager PowerShell Installer
# Engineered & Built by Sarvesh.S
# Repository: https://github.com/kavithashanmugavel2010-jpg/upm.git

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

# Safely determine script directory (handles both file execution and irm | iex)
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

$repoBaseUrl = "https://github.com/kavithashanmugavel2010-jpg/upm/raw/main"

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

# If not found locally, download directly via HTTP from GitHub repository
if (-not $installedRay) {
    Write-Host "[RAY] Downloading ray.exe from GitHub repository..." -ForegroundColor Yellow
    $rayDownloadUrl = "$repoBaseUrl/dist/ray.exe"
    try {
        Invoke-WebRequest -Uri $rayDownloadUrl -OutFile $destExe -UseBasicParsing
        if ((Test-Path $destExe) -and ((Get-Item $destExe).Length -gt 100000)) {
            $installedRay = $true
            Write-Host "[RAY] Downloaded and installed ray.exe successfully!" -ForegroundColor Green
        } else {
            throw "Downloaded file is invalid or too small."
        }
    } catch {
        Write-Warning "[RAY] Direct download from dist/ray.exe failed: $_"
        # Secondary fallback: try target/release/ray.exe
        try {
            $rayDownloadUrl2 = "$repoBaseUrl/target/release/ray.exe"
            Invoke-WebRequest -Uri $rayDownloadUrl2 -OutFile $destExe -UseBasicParsing
            if ((Test-Path $destExe) -and ((Get-Item $destExe).Length -gt 100000)) {
                $installedRay = $true
                Write-Host "[RAY] Downloaded ray.exe from release cache!" -ForegroundColor Green
            }
        } catch {
            Write-Error "[RAY] Could not download ray.exe from GitHub: $_"
            if (-not $NoPause) { Read-Host "Press Enter to exit..." }
            exit 1
        }
    }
}

# Keep upm.exe alias in bin directory for backward compatibility
try {
    $destLegacyExe = Join-Path $InstallDir "upm.exe"
    Copy-Item -Path $destExe -Destination $destLegacyExe -Force
} catch {
    # Non-fatal
}

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
    try {
        $uninstallerUrl = "$repoBaseUrl/dist/ray-uninstaller.exe"
        Invoke-WebRequest -Uri $uninstallerUrl -OutFile $destUninstaller -UseBasicParsing
        if ((Test-Path $destUninstaller) -and ((Get-Item $destUninstaller).Length -gt 50000)) {
            $installedUninstaller = $true
            Write-Host "[RAY] Installed ray-uninstaller.exe" -ForegroundColor Green
        }
    } catch {
        Write-Host "[RAY] (Uninstaller will use built-in 'ray self-uninstall')" -ForegroundColor Gray
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
    try {
        $setupUrl = "$repoBaseUrl/dist/ray-setup.exe"
        Invoke-WebRequest -Uri $setupUrl -OutFile $destSetup -UseBasicParsing
    } catch {}
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
    # Check if we were launched from a batch file or interactive prompt
    if ($Host.Name -eq "ConsoleHost" -and (-not $env:CI)) {
        Write-Host "Press Enter to finish..." -ForegroundColor Gray
        Read-Host | Out-Null
    }
}
