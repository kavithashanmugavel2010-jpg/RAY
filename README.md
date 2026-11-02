# RAY — Universal Package Manager

<div align="center">

[![Apple Silicon](https://img.shields.io/badge/Platform-Apple%20Silicon%20(M1%2FM2%2FM3%2FM4)-black?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/kavithashanmugavel2010-jpg/upm)
[![ARM64](https://img.shields.io/badge/Platform-ARM64%20%2F%20AArch64-orange?style=for-the-badge&logo=arm&logoColor=white)](https://github.com/kavithashanmugavel2010-jpg/upm)
[![Windows](https://img.shields.io/badge/Platform-Windows%20x86__64%20%7C%20ARM64-0078d7?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-setup.exe)
[![Linux](https://img.shields.io/badge/Platform-Linux%20x86__64%20%7C%20ARM64-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/kavithashanmugavel2010-jpg/upm)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

### **[👉 Click Here to Download `ray-setup.exe` (Windows 1-Click GUI Installer & Downloader)](https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-setup.exe)**

*Standalone Win32 GUI Installer • `[X] Add to PATH` Option • `[X] Uninstaller` Option • GUI Downloader Method • Built by Sarvesh.S*

</div>

---

## 🖥️ Windows Installation Options

### Option 1: ⬇️ 1-Click Downloadable GUI Installer (`ray-setup.exe`)
Download and run the standalone GUI setup executable:

👉 **[Download `ray-setup.exe`](https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-setup.exe)**

**GUI Features & Controls:**
- **`[X] Add RAY to User PATH`**: Checked by default. Automatically configures your User `PATH` and broadcasts `WM_SETTINGCHANGE` so `ray` works immediately across all shells.
- **`[X] Install RAY Uninstaller & Register in Windows Settings`**: Adds `ray-uninstaller.exe` and registers RAY into Windows Settings / Control Panel.
- **`[ ] GUI Downloader Method`**: Automatically downloads the latest fresh binaries from GitHub or installs instantly offline from the self-contained package.
- **`[ Uninstall RAY ]` Button**: Built-in graphical uninstallation button right inside the setup wizard for 1-click clean removal anytime!

---

### Option 2: ⚡ Command Prompt & PowerShell Installation (One-Line)

#### In PowerShell:
```powershell
irm https://raw.githubusercontent.com/kavithashanmugavel2010-jpg/upm/main/install.ps1 | iex
```

#### In Command Prompt (CMD):
```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/kavithashanmugavel2010-jpg/upm/main/install.ps1 | iex"
```

#### Or Double-Click `install.bat`:
Double-click `install.bat` in File Explorer. It includes pause protection so the window never closes automatically, displaying all installation steps and error diagnostics.

---

### Option 3: 🍎 Apple Silicon (macOS M1 / M2 / M3 / M4) & 🐧 Linux (ARM64 / x86_64)
Run this single command in your terminal (`Terminal.app`, `iTerm2`, or `bash`/`zsh`):
```bash
curl -fsSL https://raw.githubusercontent.com/kavithashanmugavel2010-jpg/upm/main/install.sh | bash
```

---

## ⚡ Viewing Version & System Diagnostics

To view the RAY version banner, architecture detection, author credits, and guide at any time, run:

```bash
ray version
```

Output:
```text
██████╗  █████╗ ██╗   ██╗
██╔══██╗██╔══██╗╚██╗ ██╔╝   Universal Package Manager
██████╔╝███████║ ╚████╔╝    v0.1.0 (Windows x86_64 (x86_64-pc-windows-msvc Native SIMD))
██╔══██╗██╔══██║  ╚██╔╝     Engineered & Built by Sarvesh.S
██║  ██║██║  ██║   ██║      Zero-Copy Filesystem / In-Memory SIMD / CAS
╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝

══════════════════════════════════════════════════════════════════════════
 ⚡ SUPPORTED ECOSYSTEMS & RUNTIMES
  • Python (PyPI)      : Direct wheel streaming, libdeflater SIMD, instant .venv linking
  • Node.js (npm)      : npm registry tarballs, SIMD gzip unpack, node_modules linking
  • Standalone Binaries: Native .exe & GitHub releases provisioned to ~/.ray/bin
  • System Toolchains  : Fast-path shimming and native tool execution

══════════════════════════════════════════════════════════════════════════
 📖 QUICK USAGE GUIDE & COMMANDS
  ray install <package>       Install packages (e.g. requests, npm:chalk, bin:ripgrep)
  ray x <tool> [args...]      Run any tool on-the-fly without project install (like npx/uvx)
  ray run <cmd> [args...]     Run inside active .venv or node_modules/.bin
  ray env [--reset]           Inspect or rebuild virtual environment (.venv)
  ray cache stats | clean     Display or purge Content-Addressable Storage (CAS)
  ray self-install            Install RAY into Windows and configure User PATH
  ray self-uninstall          Cleanly remove RAY and deregister from PATH
  ray info                    Display CPU SIMD vectorization & Win32 diagnostics
  ray version                 Display this banner, author credits, and guide
```

To view hardware accelerators and SIMD instruction availability:
```bash
ray info
```

---

## 📦 Supported Programming Languages & Ecosystems

RAY provides unified, microsecond-latency installation across major ecosystems:

| Ecosystem / Language | Registry & Format | Target Installation Path | Zero-Copy Linking Primitive |
| :--- | :--- | :--- | :--- |
| **Python** 🐍 | PyPI (`.whl` wheels, `pyproject.toml`, `requirements.txt`) | `.venv/Lib/site-packages` (Win) or `.venv/lib/python*/site-packages` (Mac/Linux) | Hardlink / APFS `clonefile` / ReFS block clone |
| **JavaScript / TypeScript** 🟨 | npm Registry (`.tgz` tarballs, `package.json`) | `node_modules/` + `node_modules/.bin/` | Hardlink / APFS `clonefile` / ReFS block clone |
| **Compiled Binaries & CLI Tools** ⚙️ | Direct HTTPS URLs, GitHub Releases (`.exe`, ELF, Mach-O) | `~/.ray/bin/` (or `%LOCALAPPDATA%\ray\bin`) | Direct executable link with `0755` permissions |
| **System Toolchains & Ephemeral Runtimes** ⚡ | On-the-fly ephemeral runner (`ray x <tool>`) | Ephemeral store (auto-cleaned or cached in CAS) | Instant in-memory execution without disk pollution |

---

## 🗑️ Uninstallation Methods

RAY provides both Graphical (GUI) and Command-Line (CLI) uninstallation:

### 1. GUI Uninstaller via `ray-setup.exe`
- Open **`ray-setup.exe`** and click the **`[ Uninstall RAY ]`** button.
- It prompts for confirmation, cleanly removes all binaries, deregisters from `PATH`, and unregisters from Windows Settings.

### 2. GUI Uninstaller via `ray-uninstaller.exe`
- Double-click **`ray-uninstaller.exe`** in `%LOCALAPPDATA%\ray\bin`.
- A graphical window opens with options:
  - `[X] Remove RAY from User PATH`
  - `[ ] Delete package store cache (%LOCALAPPDATA%\ray\store)`
- Click **`[ Uninstall Now ]`**.

### 3. Windows Settings (Apps & Features)
- Open **Windows Settings → Apps → Installed apps**.
- Find **RAY - Universal Package Manager** and click **Uninstall**.

### 4. CLI / Terminal Uninstaller
```powershell
ray self-uninstall -y
# Or run uninstaller directly:
ray-uninstaller.exe -y
```

---

## 🏛️ Multi-Architecture Hardware Acceleration Matrix

| Target Platform | Architecture Triple | SIMD Vectorization | Filesystem Zero-Copy Link Primitive |
| :--- | :--- | :--- | :--- |
| **Apple Silicon (M1/M2/M3/M4)** | `aarch64-apple-darwin` | **ARM NEON 128-bit + ASIMD + Hardware Crypto** | **macOS APFS `clonefile()` Copy-on-Write + POSIX hardlinks** |
| **Windows ARM64** | `aarch64-pc-windows-msvc` | **ARM NEON (Native MSVC ABI)** | **Win32 `CreateHardLinkW` + ReFS block cloning** |
| **Windows x86_64** | `x86_64-pc-windows-msvc` | **AVX2 / AVX-512 / SSE4.2 / libdeflater SIMD** | **Win32 `CreateHardLinkW` + ReFS `FSCTL_DUPLICATE_EXTENTS_TO_FILE`** |
| **Linux ARM64** | `aarch64-unknown-linux-gnu` | **ARM NEON 128-bit Vector Engine** | **POSIX `hard_link` + Btrfs/XFS `FICLONE`** |
| **Linux x86_64** | `x86_64-unknown-linux-gnu` | **AVX2 / SSE4.2 Vector Engine** | **POSIX `hard_link` + Btrfs/XFS `FICLONE`** |

---

## 👤 Author & Credits

- **Engineered & Built by**: **Sarvesh.S**
- **Repository**: [https://github.com/kavithashanmugavel2010-jpg/upm.git](https://github.com/kavithashanmugavel2010-jpg/upm.git)
- **License**: MIT
