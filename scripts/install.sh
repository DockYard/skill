#!/bin/bash
set -e

VERSION="0.1.0"
REPO="DockYard/skill"
BASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  darwin)
    OS_NAME="macos"
    ;;
  linux)
    OS_NAME="linux"
    ;;
  *)
    echo "Error: Unsupported operating system: $OS"
    exit 1
    ;;
esac

case "$ARCH" in
  x86_64|amd64)
    ARCH_NAME="x86_64"
    ;;
  arm64|aarch64)
    ARCH_NAME="aarch64"
    ;;
  *)
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

FILENAME="skill-${OS_NAME}-${ARCH_NAME}.tar.gz"
URL="${BASE_URL}/${FILENAME}"

echo "Installing skill v${VERSION} for ${OS_NAME}-${ARCH_NAME}..."
echo "Downloading from: ${URL}"

# Download
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

if command -v curl > /dev/null 2>&1; then
  curl -fsSL "$URL" -o "$FILENAME"
elif command -v wget > /dev/null 2>&1; then
  wget -q "$URL" -O "$FILENAME"
else
  echo "Error: Neither curl nor wget is available"
  exit 1
fi

# Extract
tar -xzf "$FILENAME"

# Install
INSTALL_DIR=""
if [ -w "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
elif [ -w "$HOME/.local/bin" ]; then
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"
else
  echo "Error: Cannot find a writable installation directory"
  echo "Please run with sudo or ensure ~/.local/bin exists and is writable"
  exit 1
fi

mv "skill-${OS_NAME}-${ARCH_NAME}/skill" "$INSTALL_DIR/skill"
chmod +x "$INSTALL_DIR/skill"

# Cleanup
cd -
rm -rf "$TEMP_DIR"

echo ""
echo "✅ skill installed successfully to ${INSTALL_DIR}/skill"
echo ""

# Check if install dir is in PATH
if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
  echo "⚠️  Warning: ${INSTALL_DIR} is not in your PATH"
  echo "Add it to your PATH by adding this to your shell profile:"
  echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
  echo ""
fi

# Verify installation
if command -v skill > /dev/null 2>&1; then
  echo "Verifying installation..."
  skill --version
else
  echo "Installation complete, but 'skill' command not found in PATH"
  echo "You may need to restart your shell or update your PATH"
fi
