# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-11-05

### Security
- Fixed race condition in temp directory creation by using cryptographically random names instead of timestamps
- Fixed symlink attack vulnerability by skipping symlinks during file copy operations
- Added warning when symlinks are encountered in skills

## [0.1.0] - 2024-11-05

### Added
- Initial release of skill CLI tool
- `skill init` command to initialize skills system in a project
  - Creates `skills/` directory structure
  - Generates `skills/README.md` with LLM instructions
  - Creates `skills/.gitignore` to ignore `OVERRIDE.md` files
  - Optional configuration via `--repo`, `--branch`, `--tag`, `--sha` flags
  - Prints AGENTS.md block for project integration
- `skill list` command to list all available skills from remote repository
- `skill add <name> [...]` command to add one or more skills to project
  - Fetches skills using git sparse checkout
  - Supports multiple skills in single command
  - Preserves skill directory structure with subdirectories
- `skill remove <name> [...]` command to remove skills from project
  - Prompts for confirmation if `OVERRIDE.md` exists
  - Supports multiple skills in single command
- `skill update [--all | <name> ...]` command to update skills
  - `--all` flag to update all installed skills
  - Preserves `OVERRIDE.md` files during updates
  - Shows usage when called without arguments
- `skill env` command to display configuration and version information
- `skill onboard` command to print AGENTS.md integration block
- `skill --version` / `skill -v` to display version
- `skill --help` / `skill -h` / `skill help` to display help menu
- Configuration system with hierarchy
  - Local project config: `.config/skills/skills.json`
  - Global user config: `~/.config/skills/skills.json`
  - Default repository: `git@github.com:DockYard/skills.git`
  - Support for JSON5 format (allows comments)
  - Support for branch, tag, or SHA pinning
- Git sparse checkout for efficient skill fetching (no caching)
- OVERRIDE.md support for local skill customization
  - Automatically gitignored
  - Preserved during skill updates
  - Takes precedence over SKILL.md
- Homebrew formula for easy installation
- Shell installer script for platforms without Homebrew
- Cross-platform support (macOS arm64/x86_64, Linux arm64/x86_64)
- Comprehensive documentation
  - PLAN.md - Complete project specification
  - INSTALL.md - Installation instructions
  - RELEASE.md - Release process documentation
  - HOMEBREW_SETUP.md - Homebrew distribution guide

### Technical Details
- Written in Zig 0.15.1
- Uses git for repository operations (no local cache)
- Direct repository structure (skills at root level, not in subdirectory)
- Portable across operating systems using standard library APIs
- Error messages to stderr, success messages to stdout
- Non-zero exit codes on errors

[unreleased]: https://github.com/DockYard/skill/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/DockYard/skill/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/DockYard/skill/releases/tag/v0.1.0
