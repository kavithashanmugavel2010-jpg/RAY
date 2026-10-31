#!/usr/bin/env bash
# ==============================================================================
# RAY - Universal Package Manager (Universal Shell Installer)
# Supports:
#   - Apple Silicon (macOS aarch64 / M1, M2, M3, M4)
#   - macOS Intel (x86_64)
#   - Linux ARM64 (aarch64-unknown-linux-gnu)
#   - Linux x86_64 (x86_64-unknown-linux-gnu)
#
# Engineered & Built by Sarvesh.S
# Repository: https://github.com/kavithashanmugavel2010-jpg/upm.git
# ==============================================================================

set -euo pipefail

# ANSI color codes
BOLD='\033[1m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
GRAY='\033[90m'
NC='\033[0m' # No Color

BADGE="${BOLD}\033[38;2;0;0;0m\033[48;2;0;229;255m RAY \033[0m"

echo -e "\n${BADGE} ${BOLD}Initializing RAY Universal Package Manager Setup...${NC}"

# Detect OS
OS_TYPE="$(uname -s)"
case "${OS_TYPE}" in
    Darwin)
        PLATFORM="apple-darwin"
        ;;
    Linux)
        PLATFORM="unknown-linux-gnu"
        ;;
    *)
        echo -e "${BADGE} ${RED}Error: Unsupported operating system '${OS_TYPE}'.${NC}"
        echo -e "${BADGE} On Windows, please use the GUI setup wizard or install.ps1."
        exit 1
        ;;
esac

# Detect Architecture
ARCH_TYPE="$(uname -m)"
case "${ARCH_TYPE}" in
    arm64|aarch64)
        TARGET_ARCH="aarch64"
        if [ "${OS_TYPE}" = "Darwin" ]; then
            ARCH_NAME="Apple Silicon (ARM64 M1/M2/M3/M4)"
        else
            ARCH_NAME="ARM64 / AArch64"
        fi
        ;;
    x86_64|amd64)
        TARGET_ARCH="x86_64"
        ARCH_NAME="x86_64 (64-bit Intel/AMD)"
        ;;
    *)
        echo -e "${BADGE} ${RED}Error: Unsupported CPU architecture '${ARCH_TYPE}'.${NC}"
        exit 1
        ;;
esac

TARGET_TRIPLE="${TARGET_ARCH}-${PLATFORM}"
echo -e "${BADGE} Detected platform: ${CYAN}${ARCH_NAME}${NC} (${TARGET_TRIPLE})"

# Installation directory
INSTALL_DIR="${HOME}/.ray/bin"
mkdir -p "${INSTALL_DIR}"

DEST_BIN="${INSTALL_DIR}/ray"
TEMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'ray-install')"
trap 'rm -rf "${TEMP_DIR}"' EXIT

# Determine download URL or build from source
REPO="kavithashanmugavel2010-jpg/upm"
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/ray-${TARGET_TRIPLE}"
DOWNLOADED=false

echo -e "${BADGE} Fetching binary for ${TARGET_TRIPLE}..."

if command -v curl >/dev/null 2>&1; then
    if curl -fsSL -o "${TEMP_DIR}/ray" "${RELEASE_URL}" 2>/dev/null; then
        DOWNLOADED=true
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q -O "${TEMP_DIR}/ray" "${RELEASE_URL}" 2>/dev/null; then
        DOWNLOADED=true
    fi
fi

# If GitHub release binary is not yet available, compile locally with cargo if present
if [ "${DOWNLOADED}" = "false" ]; then
    echo -e "${BADGE} ${YELLOW}Prebuilt binary release not found online yet. Checking local Rust compiler...${NC}"
    if command -v cargo >/dev/null 2>&1; then
        echo -e "${BADGE} Building RAY from source using Cargo..."
        git clone --depth 1 "https://github.com/${REPO}.git" "${TEMP_DIR}/src" 2>/dev/null || {
            # If already running inside repo directory
            if [ -f "Cargo.toml" ]; then
                cargo build --release --bin ray
                cp "target/release/ray" "${TEMP_DIR}/ray"
                DOWNLOADED=true
            fi
        }
        if [ "${DOWNLOADED}" = "false" ] && [ -d "${TEMP_DIR}/src" ]; then
            (cd "${TEMP_DIR}/src" && cargo build --release --bin ray)
            cp "${TEMP_DIR}/src/target/release/ray" "${TEMP_DIR}/ray"
            DOWNLOADED=true
        fi
    fi
fi

if [ "${DOWNLOADED}" = "false" ]; then
    echo -e "${BADGE} ${RED}Error: Could not retrieve or build RAY binary.${NC}"
    echo -e "${BADGE} Please make sure 'cargo' or 'curl' is installed, or build using: cargo build --release"
    exit 1
fi

# Copy binary to destination
cp -f "${TEMP_DIR}/ray" "${DEST_BIN}"
chmod 755 "${DEST_BIN}"

echo -e "${BADGE} ${GREEN}✓ Installed ray to ${DEST_BIN}${NC}"

# Add to PATH in shell profile
CONFIG_MODIFIED=false
EXPORT_LINE="export PATH=\"\$HOME/.ray/bin:\$PATH\""

for PROFILE in "${HOME}/.zshrc" "${HOME}/.bashrc" "${HOME}/.profile"; do
    if [ -f "${PROFILE}" ]; then
        if ! grep -q "\.ray/bin" "${PROFILE}" 2>/dev/null; then
            echo -e "\n# RAY Universal Package Manager\n${EXPORT_LINE}" >> "${PROFILE}"
            echo -e "${BADGE} ${GREEN}✓ Added ~/.ray/bin to ${PROFILE}${NC}"
            CONFIG_MODIFIED=true
        else
            CONFIG_MODIFIED=true
        fi
    fi
done

if [ "${CONFIG_MODIFIED}" = "false" ]; then
    # Create default profile depending on shell
    DEFAULT_PROFILE="${HOME}/.profile"
    if [ "${OS_TYPE}" = "Darwin" ]; then
        DEFAULT_PROFILE="${HOME}/.zprofile"
    fi
    echo -e "\n# RAY Universal Package Manager\n${EXPORT_LINE}" >> "${DEFAULT_PROFILE}"
    echo -e "${BADGE} ${GREEN}✓ Created and configured ${DEFAULT_PROFILE}${NC}"
fi

echo -e "${BADGE} ${GRAY}(Restart your shell or run 'source ~/.zshrc' / 'source ~/.bashrc' to reload PATH)${NC}\n"

# Execute version and guide
"${DEST_BIN}" version || true
