#!/bin/bash
set -e

VERSION="0.2.0"
RELEASE_DIR="release/v${VERSION}"

echo "Building skill v${VERSION} for multiple platforms..."

# Clean and create release directory
rm -rf release
mkdir -p "${RELEASE_DIR}"

# Build for macOS ARM64 (Apple Silicon)
echo "Building for macOS ARM64..."
zig build -Doptimize=ReleaseSafe -Dtarget=aarch64-macos
mkdir -p "${RELEASE_DIR}/skill-macos-aarch64"
cp zig-out/bin/skill "${RELEASE_DIR}/skill-macos-aarch64/"
cd "${RELEASE_DIR}"
tar -czf skill-macos-aarch64.tar.gz skill-macos-aarch64/
SHA256_MACOS_ARM64=$(shasum -a 256 skill-macos-aarch64.tar.gz | cut -d' ' -f1)
echo "macOS ARM64 SHA256: ${SHA256_MACOS_ARM64}"
cd -

# Build for macOS x86_64 (Intel)
echo "Building for macOS x86_64..."
zig build -Doptimize=ReleaseSafe -Dtarget=x86_64-macos
mkdir -p "${RELEASE_DIR}/skill-macos-x86_64"
cp zig-out/bin/skill "${RELEASE_DIR}/skill-macos-x86_64/"
cd "${RELEASE_DIR}"
tar -czf skill-macos-x86_64.tar.gz skill-macos-x86_64/
SHA256_MACOS_X86_64=$(shasum -a 256 skill-macos-x86_64.tar.gz | cut -d' ' -f1)
echo "macOS x86_64 SHA256: ${SHA256_MACOS_X86_64}"
cd -

# Build for Linux ARM64
echo "Building for Linux ARM64..."
zig build -Doptimize=ReleaseSafe -Dtarget=aarch64-linux
mkdir -p "${RELEASE_DIR}/skill-linux-aarch64"
cp zig-out/bin/skill "${RELEASE_DIR}/skill-linux-aarch64/"
cd "${RELEASE_DIR}"
tar -czf skill-linux-aarch64.tar.gz skill-linux-aarch64/
SHA256_LINUX_ARM64=$(shasum -a 256 skill-linux-aarch64.tar.gz | cut -d' ' -f1)
echo "Linux ARM64 SHA256: ${SHA256_LINUX_ARM64}"
cd -

# Build for Linux x86_64
echo "Building for Linux x86_64..."
zig build -Doptimize=ReleaseSafe -Dtarget=x86_64-linux
mkdir -p "${RELEASE_DIR}/skill-linux-x86_64"
cp zig-out/bin/skill "${RELEASE_DIR}/skill-linux-x86_64/"
cd "${RELEASE_DIR}"
tar -czf skill-linux-x86_64.tar.gz skill-linux-x86_64/
SHA256_LINUX_X86_64=$(shasum -a 256 skill-linux-x86_64.tar.gz | cut -d' ' -f1)
echo "Linux x86_64 SHA256: ${SHA256_LINUX_X86_64}"
cd -

# Create checksums file
cd "${RELEASE_DIR}"
shasum -a 256 *.tar.gz > checksums.txt
cd -

echo ""
echo "✅ Release builds complete!"
echo ""
echo "Files created in ${RELEASE_DIR}:"
ls -lh "${RELEASE_DIR}"/*.tar.gz
echo ""
echo "Update Formula/skill.rb with these SHA256 values:"
echo "  macOS ARM64:  ${SHA256_MACOS_ARM64}"
echo "  macOS x86_64: ${SHA256_MACOS_X86_64}"
echo "  Linux ARM64:  ${SHA256_LINUX_ARM64}"
echo "  Linux x86_64: ${SHA256_LINUX_X86_64}"
echo ""
echo "Next steps:"
echo "1. Create a GitHub release: gh release create v${VERSION} ${RELEASE_DIR}/*.tar.gz"
echo "2. Update Formula/skill.rb with the SHA256 values above"
echo "3. Commit and push the formula"
