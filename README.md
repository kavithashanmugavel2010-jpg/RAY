# RAY — Universal Package Manager

<div align="center">

[![Windows](https://img.shields.io/badge/Platform-Windows%20x86__64-0078d7?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-setup.exe)
[![Download RAY](https://img.shields.io/badge/⬇️%20Download-ray--setup.exe%20(1--Click%20Installer)-00e5ff?style=for-the-badge&logo=windows&logoColor=black)](https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-setup.exe)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

### **[👉 Click Here to Download `ray-setup.exe`](https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-setup.exe)**

*Standalone 1-click Windows installer • Automatically prompts with `[X] Add to PATH` • Built by Sarvesh.S*

```powershell
# Or install instantly via PowerShell:
irm https://raw.githubusercontent.com/kavithashanmugavel2010-jpg/upm/main/install.ps1 | iex
```

</div>

---

**RAY (Universal Package Manager)** is an ultra-high-performance, cross-ecosystem package installer and environment manager engineered natively in Rust for Windows (`x86_64-pc-windows-msvc`).

Built to surpass traditional tools like `pip`, `npm`, and `uv` in raw execution speed on Windows, RAY combines low-level Win32 kernel primitives, SIMD decompression, and in-memory streaming.

---

## ⚡ Viewing Version

To view the RAY version, banner, and author credits at any time, run:

```powershell
ray version
```

Output:
```text
 ██████╗  █████╗ ██╗   ██╗
 ██╔══██╗██╔══██╗╚██╗ ██╔╝   Universal Package Manager
 ██████╔╝███████║ ╚████╔╝    v0.1.0 (x86_64-pc-windows-msvc Native SIMD)
 ██╔══██╗██╔══██║  ╚██╔╝     Engineered & Built by Sarvesh.S
 ██║  ██║██║  ██║   ██║      Zero-Copy NTFS / In-Memory SIMD / CAS
 ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
```

---

## Key Highlights

- **Standalone Native Binary**: Compiles to a single zero-dependency machine code executable (`ray.exe`, ~3.3 MB) with `<1 ms` launch latency.
- **Content-Addressable Storage (CAS)**: Packages download and unpack once into `%LOCALAPPDATA%\ray\store\`. Subsequent installs take zero additional disk space and zero network fetches.
- **Windows Zero-Copy Linker**: Employs Win32 NTFS Hardlinks (`CreateHardLinkW`) and Dev Drive / ReFS block cloning (`FSCTL_DUPLICATE_EXTENTS_TO_FILE` via `DeviceIoControl`) for instant file population.
- **Hybrid Parallel Pipeline**: Async HTTP/2 streaming via `tokio` and `reqwest` direct into a `rayon` work-stealing thread pool.
- **SIMD In-Memory Decompression**: Uses `libdeflater` for hardware-accelerated DEFLATE/GZIP decompression of ZIP/wheel and tarball buffers with zero intermediate disk writes.
- **SIMD Integrity Hashing**: High-throughput BLAKE3 hashing at 10+ GB/s.
- **Smart Ecosystem Detection**: Detects manifests (`pyproject.toml`, `requirements.txt`, `package.json`) and CLI prefixes (`pypi:`, `npm:`, `bin:`, `sys:`) in `< 0.2 ms`.
- **Zero-Allocation Terminal UI**: Sets Windows console to `ENABLE_VIRTUAL_TERMINAL_PROCESSING` with colored badges:
  - `[PY]` (Yellow) for Python
  - `[JS]` (Bright Yellow) for JavaScript / Node
  - `[BIN]` (Bright Cyan) for Standalone CLI Binaries
  - `[SYS]` (Bright Green) for System Tools

---

## Architectural Layout

```
upupm/
├── Cargo.toml               # Release optimizations (opt-level = 3, fat LTO, codegen-units = 1)
└── src/
    ├── main.rs              # CLI entry point, command dispatch, acceleration diagnostics
    ├── terminal.rs          # Win32 Console VT Mode, zero-allocation badges, timing formatters
    ├── detector.rs          # Sub-millisecond manifest & argument ecosystem detector
    ├── cas.rs               # Content-Addressable Storage manager (%LOCALAPPDATA%\ray\store\)
    ├── binary.rs            # Standalone CLI binary installer (~/.ray/bin)
    ├── venv.rs              # Sub-millisecond Windows .venv discovery and initialization
    ├── fs/
    │   ├── mod.rs
    │   └── linker.rs        # Win32 CreateHardLinkW & ReFS FSCTL_DUPLICATE_EXTENTS_TO_FILE
    ├── pypi/
    │   └── mod.rs           # PyPI resolver, wheel selector, Rayon + libdeflater SIMD unpacker
    └── npm/
        └── mod.rs           # npm registry resolver, SIMD gzip + tar unpacker, .bin shims
```

---

## Quick Start & CLI Usage

### 1. View Version & Quickstart Guide
```powershell
ray version
```

### 2. Show Hardware Diagnostics & Capabilities
```powershell
ray info
```

### 3. Python Package Installation
```powershell
# Auto-detects Python or uses pypi: prefix
ray install requests
ray install pypi:flask

# Verbose mode with microsecond timings and BLAKE3 verification
ray install requests --verbose
```

### 4. JavaScript / Node Package Installation
```powershell
ray install npm:chalk
ray install npm:express
```

### 5. Run Any Package On-The-Fly (like `uvx` / `npx`)
Run any tool or package without prior installation or project pollution:
```powershell
# Run Python tools on-the-fly
ray x cowsay -t "Universal Package Manager"
ray x cowsay -c dragon -t "Raw Speed"
ray x ruff check .

# Run via 'ray run' with automatic ephemeral fallback
ray run cowsay -c tux -t "Linux Tux on Windows"
```

### 6. Cache Management
```powershell
# Show CAS statistics (package count, total files, disk size)
ray cache stats

# Show CAS directory path
ray cache dir

# Clean global cache
ray cache clean
```

---

## Building from Source

Prerequisites: Rust 1.80+ with `x86_64-pc-windows-msvc` toolchain.

```powershell
# Development build
cargo build

# Maximum-performance Release Build
cargo build --release
```
The compiled release executables are placed at:
- `target\release\ray.exe` (Main CLI)
- `target\release\ray-setup.exe` (1-Click Standalone GUI Setup Wizard with embedded binary)
- `target\release\ray-installer.exe` (Interactive Terminal Installer)
- `target\release\ray-uninstaller.exe` (Windows Uninstaller)

---

## Installation

RAY offers two easy ways to install on Windows:

### 1. ⬇️ Downloadable Link (1-Click GUI Setup)
Download and run the standalone installer just like Python:

👉 **[Download `ray-setup.exe` (4.2 MB)](https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-setup.exe)**

1. Double-click the downloaded **`ray-setup.exe`**.
2. An installation screen opens with **`[X] Add RAY to PATH`** already pre-checked.
3. Click **`[ Install Now ]`**.
4. A prompt appears: *"Thanks for choosing RAY! Built by Sarvesh.S"*.
5. The installer closes and automatically opens a new PowerShell window with `ray version` running!

---

### 2. ⚡ Terminal CLI Install (One-Line Command)
Open PowerShell and run this single command:

```powershell
irm https://raw.githubusercontent.com/kavithashanmugavel2010-jpg/upm/main/install.ps1 | iex
```

This automatically downloads, installs RAY into `%LOCALAPPDATA%\ray\bin`, configures your User `PATH`, and launches `ray version`.

---

## Uninstallation & Cleanup

RAY provides multiple ways to cleanly remove itself, deregister from PATH, and delete cached packages:

### Option A: Standalone Native Uninstaller (`ray-uninstaller.exe`)
When installed, `ray-uninstaller.exe` is placed directly in the install directory (default: `%LOCALAPPDATA%\ray\bin`).
```powershell
# Interactive uninstaller wizard:
ray-uninstaller.exe

# Non-interactive uninstall (removes from PATH and cleans binaries):
ray-uninstaller.exe --remove-from-path -y

# Also clean package cache store (%LOCALAPPDATA%\ray\store):
ray-uninstaller.exe --remove-from-path --clean-cache -y
```

### Option B: Built-in `ray self-uninstall`
```powershell
# Interactive prompts for PATH and cache cleanup:
ray self-uninstall

# Fully automatic removal:
ray self-uninstall --remove-from-path --clean-cache -y
```

### Option C: Windows Installed Apps / Control Panel
RAY automatically registers in Windows **Settings → Apps → Installed apps** (or Control Panel → Programs and Features). You can click **Uninstall** directly from Windows Settings!

### Option D: PowerShell Uninstaller (`uninstall.ps1`)
```powershell
# Remove RAY and remove from PATH:
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1

# Remove RAY, remove from PATH, and delete package cache:
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -CleanCache -Force
```

### Option E: Double-Click Batch Uninstaller (`uninstall.bat`)
Double-click `uninstall.bat` in Windows File Explorer or run from CMD.
