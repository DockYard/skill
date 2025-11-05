# Homebrew Setup Guide

This guide explains how to make `skill` available via Homebrew.

## Quick Start

For the simplest setup, you can use the existing repository as a tap:

### 1. Build and create a release

```bash
# Build release binaries
./scripts/build-release.sh

# Create GitHub release
gh release create v0.1.0 \
  --title "v0.1.0" \
  --notes "Initial release of skill CLI" \
  release/v0.1.0/*.tar.gz
```

### 2. Update the formula with checksums

After creating the release, update `Formula/skill.rb` with the SHA256 values printed by the build script.

### 3. Commit and push

```bash
git add Formula/skill.rb
git commit -m "Add Homebrew formula"
git push origin main
```

### 4. Users can now install

```bash
# Install directly from your tap
brew install DockYard/skill/skill

# Or tap it first, then install
brew tap DockYard/skill
brew install skill
```

## How It Works

### Repository as Tap

When you put a `Formula/` directory in your repository, Homebrew can use it as a tap directly:

```
DockYard/skill/
  Formula/
    skill.rb      ← Homebrew formula
  src/            ← Source code
  scripts/        ← Build scripts
  ...
```

Users reference it as: `DockYard/skill/skill`
- `DockYard/skill` = the tap (your repository)
- `skill` = the formula name

### What the Formula Does

The formula (`Formula/skill.rb`):
1. Detects the user's platform (macOS/Linux, ARM64/x86_64)
2. Downloads the appropriate pre-built binary from your GitHub release
3. Verifies the checksum matches
4. Installs the binary to the Homebrew bin directory

### Installation Methods for Users

Once set up, users have several options:

```bash
# Method 1: Direct install
brew install DockYard/skill/skill

# Method 2: Tap first, then install
brew tap DockYard/skill
brew install skill

# Method 3: Shell script (no Homebrew required)
curl -fsSL https://raw.githubusercontent.com/DockYard/skill/main/scripts/install.sh | sh
```

## Alternative: Dedicated Tap Repository

If you prefer to separate the formula from the main repository:

### 1. Create homebrew-skill repository

Create a new repository: `DockYard/homebrew-skill`

### 2. Add the formula

Copy `Formula/skill.rb` to the root of `homebrew-skill`:

```
DockYard/homebrew-skill/
  skill.rb        ← Formula at root
  README.md
```

### 3. Users install with

```bash
brew tap DockYard/skill
brew install skill
```

## Testing Your Formula

Before releasing, test the formula locally:

```bash
# Test installation
brew install --build-from-source Formula/skill.rb

# Or with a local tap
brew tap DockYard/skill /path/to/your/skill/repo
brew install skill

# Test the audit
brew audit --strict Formula/skill.rb

# Test uninstall
brew uninstall skill
```

## Updating for New Releases

For each new release:

1. Update version in `scripts/build-release.sh`
2. Run `./scripts/build-release.sh`
3. Create GitHub release with binaries
4. Update `Formula/skill.rb`:
   - Update `version`
   - Update all SHA256 checksums
   - Update download URLs if version changed
5. Commit and push

Users can then update with:
```bash
brew update
brew upgrade skill
```

## Benefits of This Approach

✅ Simple - No separate repository to maintain
✅ Integrated - Formula lives with your code
✅ Standard - Follows Homebrew conventions
✅ Flexible - Users can still build from source if desired

## Next Steps

1. Run `./scripts/build-release.sh` to create binaries
2. Create a GitHub release with those binaries
3. Update `Formula/skill.rb` with the checksums
4. Commit and push
5. Tell users to `brew install DockYard/skill/skill`
