# Installing skill

The `skill` CLI tool can be installed in several ways:

## Option 1: Homebrew (macOS and Linux)

```bash
# Add the DockYard tap
brew tap DockYard/skill

# Install skill
brew install skill
```

## Option 2: Shell Script Installer

This method downloads a pre-built binary for your platform:

```bash
curl -fsSL https://raw.githubusercontent.com/DockYard/skill/main/scripts/install.sh | sh
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/DockYard/skill/main/scripts/install.sh | sh
```

## Option 3: Download Binary Manually

1. Go to the [releases page](https://github.com/DockYard/skill/releases)
2. Download the appropriate binary for your platform:
   - macOS ARM64 (Apple Silicon): `skill-macos-aarch64.tar.gz`
   - macOS x86_64 (Intel): `skill-macos-x86_64.tar.gz`
   - Linux ARM64: `skill-linux-aarch64.tar.gz`
   - Linux x86_64: `skill-linux-x86_64.tar.gz`
3. Extract and move to your PATH:
   ```bash
   tar -xzf skill-*.tar.gz
   sudo mv skill-*/skill /usr/local/bin/
   ```

## Option 4: Build from Source

Requirements:
- Zig 0.15.1 or later
- Git

```bash
git clone https://github.com/DockYard/skill.git
cd skill
zig build -Doptimize=ReleaseSafe
sudo cp zig-out/bin/skill /usr/local/bin/
```

## Verify Installation

After installation, verify that `skill` is working:

```bash
skill --version
```

You should see: `skill version 0.1.0`

## Next Steps

After installation:

1. Initialize a project: `skill init`
2. List available skills: `skill list`
3. Add skills to your project: `skill add <skill-name>`

For full documentation, see the [README](README.md) or run `skill --help`.
