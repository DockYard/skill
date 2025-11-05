# Release Process

This document describes how to create a new release of `skill`.

## Prerequisites

- Zig 0.15.1 or later installed
- GitHub CLI (`gh`) installed and authenticated
- Write access to the DockYard/skill repository

## Steps

### 1. Update Version

Update the version in these files:
- `build.zig.zon` - Update `.version`
- `src/main.zig` - Update `VERSION` constant
- `src/commands.zig` - Update version in `env` command
- `scripts/build-release.sh` - Update `VERSION` variable
- `scripts/install.sh` - Update `VERSION` variable
- `Formula/skill.rb` - Update `version`

### 2. Build Release Binaries

Run the release build script:

```bash
./scripts/build-release.sh
```

This will:
- Build binaries for all supported platforms (macOS arm64/x86_64, Linux arm64/x86_64)
- Create tar.gz archives
- Generate SHA256 checksums
- Place everything in `release/v{VERSION}/`

### 3. Create GitHub Release

Create a new release and upload the binaries:

```bash
VERSION="0.1.0"
gh release create "v${VERSION}" \
  --title "v${VERSION}" \
  --notes "Release notes here" \
  release/v${VERSION}/*.tar.gz
```

### 4. Update Homebrew Formula

After the release is created, update `Formula/skill.rb` with the SHA256 checksums printed by the build script.

Replace the placeholder values:
- `PLACEHOLDER_ARM64_SHA256` → macOS ARM64 SHA256
- `PLACEHOLDER_X86_64_SHA256` → macOS x86_64 SHA256
- `PLACEHOLDER_LINUX_ARM64_SHA256` → Linux ARM64 SHA256
- `PLACEHOLDER_LINUX_X86_64_SHA256` → Linux x86_64 SHA256

### 5. Commit and Push

```bash
git add Formula/skill.rb
git commit -m "Update Homebrew formula for v${VERSION}"
git push origin main
```

### 6. Test Installation

Test the installation methods:

#### Homebrew
```bash
brew tap DockYard/skill
brew install skill
skill --version
```

#### Shell Script
```bash
curl -fsSL https://raw.githubusercontent.com/DockYard/skill/main/scripts/install.sh | sh
skill --version
```

## Homebrew Tap Setup

The first time you release, you'll need to set up the Homebrew tap:

### Option 1: Use the skill repository as the tap

Users would install with:
```bash
brew install DockYard/skill/skill
```

No additional repository needed - the formula in `Formula/skill.rb` is used directly.

### Option 2: Create a separate homebrew-skill repository

1. Create a new repository: `DockYard/homebrew-skill`
2. Copy `Formula/skill.rb` to the root of that repository
3. Users install with:
   ```bash
   brew tap DockYard/skill
   brew install skill
   ```

**Recommendation:** Use Option 1 for simplicity unless you plan to have multiple formulas in the tap.

## Troubleshooting

### Binary not working on target platform

- Ensure you're building with the correct target triple
- Verify the binary is not stripped of necessary symbols
- Check that the binary has execute permissions in the tar.gz

### SHA256 mismatch in Homebrew

- Re-run the build script to get the correct checksums
- Ensure you're using the correct tar.gz files from the release

### Install script fails

- Check that the release assets are publicly accessible
- Verify the URLs in the install script match the actual release URLs
- Test locally by downloading a release asset manually
