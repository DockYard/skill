# skill

A command-line tool for vendoring and managing LLM skills from a central repository.

## What is skill?

`skill` helps you manage reusable AI agent instructions (called "skills") in your projects. Instead of copying and maintaining skill files manually, `skill` lets you:

- 📦 **Vendor skills** from a central repository into your project
- 🔄 **Keep skills up-to-date** with a single command
- ✏️ **Override skills locally** without modifying the originals
- 🎯 **Pin to specific versions** using branches, tags, or commit SHAs

## Quick Start

### Installation

**macOS/Linux (Homebrew):**
```bash
brew install DockYard/skill/skill
```

**Shell script:**
```bash
curl -fsSL https://raw.githubusercontent.com/DockYard/skill/main/scripts/install.sh | sh
```

See [INSTALL.md](INSTALL.md) for more installation options.

### Basic Usage

```bash
# Initialize skills in your project
skill init

# List available skills
skill list

# Add skills to your project
skill add zig testing

# Update all skills
skill update --all
```

## How It Works

### Repository Structure

Skills are stored in a central git repository with each skill as a top-level directory:

```
skills-repo/
  zig/
    SKILL.md
    resources/
    scripts/
  testing/
    SKILL.md
  docs/
    SKILL.md
```

### Project Structure

After running `skill init` and adding skills, your project looks like:

```
your-project/
  .config/
    skills/
      skills.json           # Configuration
  skills/
    .gitignore              # Ignores OVERRIDE.md files
    README.md               # Instructions for AI agents
    zig/
      SKILL.md              # Vendored skill
      resources/
      scripts/
    testing/
      SKILL.md
```

### Local Overrides

Create `OVERRIDE.md` in any skill directory to customize it locally:

```bash
# Add your local modifications
echo "# Local customizations" > skills/zig/OVERRIDE.md
```

- `OVERRIDE.md` takes precedence over `SKILL.md`
- Automatically gitignored (stays local)
- Preserved during `skill update`

## Commands

### `skill init`

Initialize the skills system in your project.

```bash
# Use default repository
skill init

# Use custom repository
skill init --repo git@github.com:yourorg/skills.git

# Pin to specific version
skill init --repo git@github.com:yourorg/skills.git --tag v1.0.0
skill init --repo git@github.com:yourorg/skills.git --branch develop
skill init --repo git@github.com:yourorg/skills.git --sha abc123
```

**Options:**
- `--repo <url>` - Git repository URL (default: `git@github.com:DockYard/skills.git`)
- `--branch <name>` - Pin to a specific branch
- `--tag <name>` - Pin to a specific tag
- `--sha <hash>` - Pin to a specific commit

### `skill list`

List all available skills from the configured repository.

```bash
skill list
```

### `skill add`

Add one or more skills to your project.

```bash
# Add single skill
skill add zig

# Add multiple skills
skill add zig testing docs
```

Skills are fetched from the remote repository and copied into your `skills/` directory.

### `skill remove`

Remove one or more skills from your project.

```bash
# Remove single skill
skill remove zig

# Remove multiple skills
skill remove zig testing
```

If a skill has an `OVERRIDE.md` file, you'll be prompted for confirmation.

### `skill update`

Update skills to the latest version from the repository.

```bash
# Show usage and list installed skills
skill update

# Update specific skills
skill update zig testing

# Update all installed skills
skill update --all
```

Updates preserve your local `OVERRIDE.md` files.

### `skill env`

Display configuration information.

```bash
skill env
```

Shows:
- Version
- Config file location
- Repository URL
- Branch/tag/SHA (if pinned)

### `skill onboard`

Print the AGENTS.md integration block.

```bash
skill onboard
```

Shows instructions for integrating the skills system into your project's `AGENTS.md` file.

### `skill --version`

Display version information.

```bash
skill --version
skill -v
```

### `skill --help`

Display help information.

```bash
skill --help
skill -h
skill help
```

## Configuration

Configuration is loaded in this order:

1. **Local project**: `.config/skills/skills.json` (in project root)
2. **Global user**: `~/.config/skills/skills.json`
3. **Default**: `git@github.com:DockYard/skills.git`

### Configuration Format

`.config/skills/skills.json` (JSON5 format, comments allowed):

```json5
{
  "repo": "git@github.com:DockYard/skills.git"
  // "branch": "main"
  // "tag": "v1.0.0"
  // "sha": "abc123def456"
}
```

**Rules:**
- Only one of `branch`, `tag`, or `sha` can be specified
- If none specified, uses repository's HEAD
- Comments are supported (JSON5 format)

## Use Cases

### Development Team

Share common AI agent instructions across your team:

```bash
# Each developer initializes
skill init

# Add the skills your project uses
skill add testing code-review

# Team updates skills as they evolve
skill update --all
```

### Multiple Projects

Use different skill versions per project:

```bash
# Project A: use stable release
cd project-a
skill init --tag v1.0.0
skill add zig

# Project B: use latest development
cd ../project-b
skill init --branch develop
skill add zig
```

### Local Customization

Customize skills without modifying the originals:

```bash
skill add zig

# Add local-specific instructions
cat >> skills/zig/OVERRIDE.md << 'EOF'
# Project-Specific Zig Guidelines

- Always use Zig 0.15.1 for this project
- Run tests with `zig build test -Dtest-filter=critical`
EOF
```

## For LLM/AI Agents

When you run `skill init`, a `skills/README.md` file is created with instructions for AI agents. The key points:

1. **Read order**: `AGENTS.md` → `skills/README.md` → `SKILL.md` → `OVERRIDE.md`
2. **Precedence**: `OVERRIDE.md` overrides `SKILL.md`
3. **Discovery**: List `skills/` directory to find available skills

Add this block to your `AGENTS.md` (or run `skill onboard` to see it):

```markdown
<!-- BEGIN: skills-system -->
Agents MUST resolve guidance in this order:

1) Project-level behavior: `AGENTS.md` (this file)
2) Skills system rules: `skills/README.md`
3) For each required skill:
   - Read `skills/<name>/SKILL.md`
   - If `skills/<name>/OVERRIDE.md` exists, its guidance OVERRIDES `SKILL.md`

Never assume all skills exist; only use those present under `skills/`.
If two skills conflict, prefer the more specific skill's OVERRIDES, then SKILL.md.
<!-- END: skills-system -->
```

## Creating Your Own Skills Repository

Want to create your own skills repository?

1. **Create a git repository** with skills as top-level directories:
   ```
   your-skills/
     skill-one/
       SKILL.md
     skill-two/
       SKILL.md
       resources/
   ```

2. **Each skill must have a `SKILL.md`** file containing instructions for AI agents

3. **Skills can include additional files** like resources, scripts, or templates

4. **Use it in your project**:
   ```bash
   skill init --repo git@github.com:yourorg/your-skills.git
   skill list
   skill add skill-one
   ```

## Requirements

- **Git** must be installed and in your PATH
- **SSH access** to your skills repository (for default setup)
  - Or use HTTPS URLs with credentials configured

## Building from Source

Requirements:
- Zig 0.15.1 or later
- Git

```bash
git clone https://github.com/DockYard/skill.git
cd skill
zig build -Doptimize=ReleaseSafe
sudo cp zig-out/bin/skill /usr/local/bin/
```

## Documentation

- [INSTALL.md](INSTALL.md) - Installation instructions
- [PLAN.md](PLAN.md) - Complete project specification
- [CHANGELOG.md](CHANGELOG.md) - Version history
- [RELEASE.md](RELEASE.md) - Release process (for maintainers)
- [HOMEBREW_SETUP.md](HOMEBREW_SETUP.md) - Homebrew distribution guide

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

[MIT License](LICENSE)

## About DockYard

`skill` is created and maintained by [DockYard](https://dockyard.com).

DockYard is a digital product consultancy specializing in user experience, web applications, and mobile applications.
