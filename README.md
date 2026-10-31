# RAY — Universal Package Manager

<div align="center">

[![Apple Silicon](https://img.shields.io/badge/Platform-Apple%20Silicon%20(M1%2FM2%2FM3%2FM4)-black?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/kavithashanmugavel2010-jpg/upm)
[![ARM64](https://img.shields.io/badge/Platform-ARM64%20%2F%20AArch64-orange?style=for-the-badge&logo=arm&logoColor=white)](https://github.com/kavithashanmugavel2010-jpg/upm)
[![Windows](https://img.shields.io/badge/Platform-Windows%20x86__64%20%7C%20ARM64-0078d7?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-setup.exe)
[![Linux](https://img.shields.io/badge/Platform-Linux%20x86__64%20%7C%20ARM64-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/kavithashanmugavel2010-jpg/upm)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

### **[👉 Click Here to Download `ray-setup.exe` (Windows 1-Click GUI Installer)](https://github.com/kavithashanmugavel2010-jpg/upm/raw/main/dist/ray-setup.exe)**

*Multi-Architecture • Apple Silicon ARM64 • Windows x86_64 / ARM64 • Linux ARM64 / x86_64 • Built by Sarvesh.S*

</div>

---

## ⚡ 1-Line Universal Installation

### 🍎 Apple Silicon (macOS M1 / M2 / M3 / M4) & 🐧 Linux (ARM64 / x86_64)
Run this single command in your terminal (Terminal.app, iTerm2, or bash/zsh):
```bash
curl -fsSL https://raw.githubusercontent.com/kavithashanmugavel2010-jpg/upm/main/install.sh | bash
```
*Detects your CPU architecture (`aarch64` / `arm64` vs `x86_64`), installs `ray` to `~/.ray/bin`, configures your shell profile (`~/.zshrc` / `~/.bashrc`), and displays `ray version`.*

### 🪟 Windows (x86_64 & ARM64)
Open PowerShell and run:
```powershell
irm https://raw.githubusercontent.com/kavithashanmugavel2010-jpg/upm/main/install.ps1 | iex
```
*Or double-click **`dist/ray-setup.exe`** to install via the native Win32 GUI setup wizard.*

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
██████╔╝███████║ ╚████╔╝    v0.1.0 (Apple Silicon ARM64 (aarch64-apple-darwin Native NEON))
██╔══██╗██╔══██║  ╚██╔╝     Engineered & Built by Sarvesh.S
██║  ██║██║  ██║   ██║      Zero-Copy Filesystem / In-Memory SIMD / CAS
╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
```

To view hardware accelerators, SIMD instruction availability, and link primitives on your active machine:
```bash
ray info
```

---

## 📦 Supported Programming Languages & Ecosystems

RAY is built as a single universal manager designed to replace fragmented tools (`pip`, `npm`, `npx`, `uv`, `curl|sh`) with a unified, zero-copy architecture:

| Ecosystem / Language | Registry & Format | Target Installation Path | Zero-Copy Linking Primitive |
| :--- | :--- | :--- | :--- |
| **Python** 🐍 | PyPI (`.whl` wheels, `pyproject.toml`, `requirements.txt`) | `.venv/Lib/site-packages` (Win) or `.venv/lib/python*/site-packages` (Mac/Linux) | Hardlink / APFS `clonefile` / ReFS block clone |
| **JavaScript / TypeScript** 🟨 | npm Registry (`.tgz` tarballs, `package.json`) | `node_modules/` + `node_modules/.bin/` | Hardlink / APFS `clonefile` / ReFS block clone |
| **Compiled Binaries & CLI Tools** ⚙️ | Direct HTTPS URLs, GitHub Releases (`.exe`, ELF, Mach-O) | `~/.ray/bin/` (or `%LOCALAPPDATA%\ray\bin`) | Direct executable link with `0755` permissions |
| **System Toolchains & Ephemeral Runtimes** ⚡ | On-the-fly ephemeral runner (`ray x <tool>`) | Ephemeral store (deleted automatically or cached in CAS) | Instant in-memory execution without disk pollution |

### Supported Extensions & Package Types
- **Python**: `.whl` (Wheel archives with direct ZIP streaming), `requirements.txt`, `pyproject.toml`
- **JavaScript / Node**: `.tgz` (Gzip-compressed tarballs), `package.json`
- **Standalone Binaries**: Native Mach-O executables (macOS), ELF binaries (Linux), PE32+ `.exe` (Windows)
- **Archives**: `.tar.gz`, `.tgz`, `.zip` with in-memory SIMD unpacking

---

## 🏛️ Multi-Architecture Hardware Acceleration Matrix

RAY detects your CPU and operating system at runtime to activate the fastest hardware accelerators:

| Target Platform | Architecture Triple | SIMD Vectorization | Filesystem Zero-Copy Link Primitive |
| :--- | :--- | :--- | :--- |
| **Apple Silicon (M1/M2/M3/M4)** | `aarch64-apple-darwin` | **ARM NEON + ASIMD + Hardware Crypto** | **macOS APFS `clonefile()` Copy-on-Write + POSIX hardlinks** |
| **Windows ARM64** | `aarch64-pc-windows-msvc` | **ARM NEON (Native MSVC ABI)** | **Win32 `CreateHardLinkW` + ReFS block cloning** |
| **Windows x86_64** | `x86_64-pc-windows-msvc` | **AVX2 / AVX-512 / SSE4.2 / libdeflater SIMD** | **Win32 `CreateHardLinkW` + ReFS `FSCTL_DUPLICATE_EXTENTS_TO_FILE`** |
| **Linux ARM64** | `aarch64-unknown-linux-gnu` | **ARM NEON 128-bit Vector Engine** | **POSIX `hard_link` + Btrfs/XFS `FICLONE`** |
| **Linux x86_64** | `x86_64-unknown-linux-gnu` | **AVX2 / SSE4.2 Vector Engine** | **POSIX `hard_link` + Btrfs/XFS `FICLONE`** |

---

## 🚀 CLI Commands & Usage

### 1. Install Packages
Auto-detects whether the package is Python, npm, or a binary:
```bash
# Python (PyPI)
ray install requests
ray install flask --verbose

# JavaScript / Node (npm)
ray install npm:chalk
ray install npm:express

# Standalone CLI Binaries from GitHub or Direct URL
ray install https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-apple-darwin.tar.gz
```

### 2. Run Tools On-The-Fly (like `npx` / `uvx`)
Execute any package without polluting your global environment or project files:
```bash
# Run cowsay on-the-fly in milliseconds:
ray x cowsay "RAY engineered by Sarvesh.S"

# Run ruff linter directly:
ray x ruff check .

# Run tux cow:
ray x cowsay -c tux "Universal Package Manager"
```

### 3. Virtual Environment Management (`.venv`)
```bash
# Create or inspect high-performance virtualenv:
ray env

# Reset and recreate clean environment:
ray env --reset
```

### 4. Cache Store Management (CAS)
```bash
# View storage statistics and package count:
ray cache stats

# Show CAS root directory:
ray cache dir

# Clean global cache store:
ray cache clean
```

---

## 🛠️ Building from Source

### Prerequisites
- Rust 1.80+ (`rustup`)
- Git

### Build for Current Host Architecture
```bash
# Build release binary:
cargo build --release --bin ray

# The binary will be available at:
# macOS / Linux: target/release/ray
# Windows:       target/release/ray.exe
```

### Cross-Compiling for Apple Silicon and ARM
```bash
# Add targets:
rustup target add aarch64-apple-darwin
rustup target add aarch64-pc-windows-msvc
rustup target add aarch64-unknown-linux-gnu

# Build for Apple Silicon (on macOS):
cargo build --release --target aarch64-apple-darwin --bin ray

# Build for Linux ARM64:
cargo build --release --target aarch64-unknown-linux-gnu --bin ray
```

---

## 🗑️ Uninstallation & Removal

### On macOS / Linux:
```bash
ray self-uninstall --remove-from-path --clean-cache -y
```
*Or manually remove `~/.ray` and the export line in `~/.zshrc` / `~/.bashrc`.*

### On Windows:
- **GUI**: Go to **Windows Settings → Apps → Installed apps**, locate **RAY - Universal Package Manager**, and click **Uninstall**.
- **CLI**: Run `ray self-uninstall --remove-from-path --clean-cache -y` or `dist\ray-uninstaller.exe`.

---

## 👤 Author & Credits

- **Engineered & Built by**: **Sarvesh.S**
- **Repository**: [https://github.com/kavithashanmugavel2010-jpg/upm.git](https://github.com/kavithashanmugavel2010-jpg/upm.git)
- **License**: MIT
