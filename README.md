# n0dom

<div align="center">

**A modern dotfiles manager for Arch Linux**

*Simplify your configuration management with intelligent two-way sync*

[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](https://github.com/noeltz/n0dom)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Arch Linux](https://img.shields.io/badge/Arch%20Linux-supported-1793d1.svg)](https://archlinux.org)

</div>

---

## Why n0dom?

- **Single command workflow** - `n0dom sync` does everything
- **Two-way synchronization** - Changes flow both ways intelligently
- **Built-in safety** - Automatic backups, conflict resolution, and rollback
- **Zero configuration** - Works out of the box, configure only if needed
- **Arch-focused** - Optimized for Arch Linux and Arch-based distributions

## Features

| Feature | Description |
|---------|-------------|
| 🔄 **Two-Way Sync** | Intelligent merge between local and remote changes |
| 🔗 **Symlink Management** | Automatic symlink creation with conflict detection |
| 💾 **Automatic Backups** | Timestamped backups before every operation |
| 🔒 **Safety First** | Confirmation prompts, secrets detection, atomic operations |
| 🏥 **Doctor Command** | Diagnose and fix common issues automatically |
| 📦 **Package Tracking** | Export and import pacman package lists |
| 🖥️ **Machine-Specific** | Hostname-based configuration overrides |
| 🔀 **Conflict Resolution** | Interactive merge with meld integration |
| 🌐 **GitHub Integration** | Seamless auth via `gh` CLI |

## Quick Start

### Installation

```bash
curl -fsSL https://raw.githubusercontent.com/noeltz/n0dom/main/install.sh | bash
```

The installer will:
- Detect your Arch-based distribution
- Install all dependencies automatically
- Configure git with your GitHub identity
- Add n0dom to your PATH

### First Time Setup

**Option A: Export your current dotfiles**

```bash
n0dom init                      # Create new repository
n0dom track ~/.bashrc           # Track files
n0dom track ~/.config/nvim
n0dom sync "Initial commit"     # Sync and push to GitHub
```

**Option B: Import to a new machine**

```bash
n0dom clone username/dotfiles   # Clone your repo
n0dom sync                      # Activate all dotfiles
n0dom packages import           # Install packages (optional)
```

## Commands

### Setup

| Command | Description |
|---------|-------------|
| `n0dom init` | Initialize a new dotfiles repository |
| `n0dom clone <repo>` | Clone an existing repository |

### Core Operations

| Command | Description |
|---------|-------------|
| `n0dom sync [message]` | **Full sync**: pull, merge, commit, push |
| `n0dom track <path>` | Add a file/directory to tracking |
| `n0dom untrack <path>` | Remove a file from tracking |
| `n0dom add` | Auto-add untracked files in tracked directories |

### Status & Diagnostics

| Command | Description |
|---------|-------------|
| `n0dom status` | Show repository and sync status |
| `n0dom diff [file]` | Show differences between repo and home |
| `n0dom doctor` | Run diagnostics and health checks |
| `n0dom clean` | Remove broken symlinks |

### Backup & Restore

| Command | Description |
|---------|-------------|
| `n0dom backup` | Create manual backup |
| `n0dom restore [id]` | Restore from backup (lists if no ID) |
| `n0dom cleanup` | Remove old backups based on retention policy |

### Package Management

| Command | Description |
|---------|-------------|
| `n0dom packages export` | Export installed packages to repo |
| `n0dom packages import` | Install packages from repo list |

### Maintenance

| Command | Description |
|---------|-------------|
| `n0dom update` | Update n0dom to latest version |
| `n0dom help` | Show help message |

## Options

All commands support these global options:

```
-v, --verbose          Show detailed output
-n, --no-backup        Skip automatic backups
-d, --dry-run          Preview changes without applying
-y, --yes, --force     Auto-confirm all prompts
-c, --check            Non-interactive mode (for doctor: report only, exit 1 on issues)
```

## How It Works

### The Sync Philosophy

One command does it all:

```
n0dom sync "Your message"
```

This single command:

1. **Pulls** remote changes from GitHub
2. **Detects** local modifications
3. **Merges** changes with conflict resolution
4. **Commits** with your message
5. **Pushes** back to GitHub

### Directory Structure

```
~/.config/n0dom/
└── config.yaml              # Configuration (optional)

~/.local/share/n0dom/
├── backups/                 # Automatic backups
│   └── YYYYMMDD_HHMMSS_operation/
├── repo/                    # Git repository
│   ├── .git/
│   ├── .n0domignore         # Ignore patterns
│   ├── .n0dom-packages      # Package list
│   └── [your dotfiles...]
└── n0dom.lock               # Lock file (concurrent ops)
```

### Safety Features

#### Confirmation Prompts

Destructive operations require confirmation:

```bash
$ n0dom sync
⚠ Removing directory: .config/nvim
Proceed? [y/N]
```

Use `--force` to skip:

```bash
n0dom sync --force
```

#### Automatic Backups

Created before every sync operation:

```bash
$ n0dom restore
Available backups:
BACKUP ID                       DATE                 TYPE
20260219_143022_pre-sync        2026-02-19 14:30     pre-sync
20260218_090000_pre-clone       2026-02-18 09:00     pre-clone
```

#### Secrets Protection

Warns about potentially sensitive files:

```bash
$ n0dom track ~/.ssh/id_rsa
⚠ Potentially sensitive file detected: id_rsa
This file may contain secrets. Track anyway? [y/N]
```

#### Atomic Operations

If sync fails, automatic rollback:

```bash
$ n0dom sync
✗ Failed to push to remote
⚠ Rolling back due to error...
✓ Restored from backup: 20260219_143022_pre-sync
```

## Advanced Features

### Machine-Specific Configurations

Use hostname-based file overrides:

```
.bashrc              # Default version
.bashrc.laptop       # Used on machine named "laptop"
.bashrc.desktop      # Used on machine named "desktop"
.config/nvim/init.lua
.config/nvim/init.lua.work
```

n0dom automatically selects the hostname-specific version when available.

### Package List Management

Track your installed packages:

```bash
# Export current packages
n0dom packages export
# Creates .n0dom-packages in your repo

# Import on a new machine
n0dom packages import
# Installs packages using pacman (repo) and AUR helper (AUR)
```

**Package file format** (`.n0dom-packages`):

```
# n0dom package list v2
# Format: package:origin
# Origins: repo, aur

git:repo
vim:repo
neovim:repo
yay:aur
google-chrome:aur
```

- **Repo packages**: Installed with `pacman`
- **AUR packages**: Installed with `paru` or `yay` (auto-detected)

**Requirements:**
- AUR packages require an AUR helper (`paru` or `yay`) to be installed
- Import will fail if AUR packages are found but no AUR helper is available

### Conflict Resolution

When both local and remote have changes:

```bash
$ n0dom sync
⚠ Conflict detected: .bashrc
Both home and repo versions have changed
Options:
  [r] Use repository version (overwrite home)
  [l] Use local version (update repo)
  [s] Skip this file
  [d] Show diff
Choose action [r/l/s/d]:
```

### Dry Run Preview

See what will happen before committing:

```bash
$ n0dom sync --dry-run

Sync Summary:
  In sync: 15 files
  Repo only: 3 files (will link to home)
  Home only: 1 files (will copy to repo)
  Conflicts: 1 files (need resolution)

Files to link (repo -> home):
  LINK ~/.bashrc
  LINK ~/.zshrc
  LINK ~/.config/nvim

Files to track (home -> repo):
  TRACK ~/.config/alacritty

Files with conflicts:
  CONFLICT ~/.gitconfig

Dry run - no changes made
```

### Doctor Command

Diagnose and fix issues interactively:

```bash
$ n0dom doctor

N0DOM Doctor - Diagnostics

Checking dependencies...
✓ git: 2.53.0
✓ gh: 2.86.0
✓ yq: installed

Checking merge tools...
✓ meld: installed
✓ vimdiff: installed
  Configured resolver: auto

Checking Git configuration...
✗ git user.email: not set
✗ git user.name: not set

Checking GitHub authentication...
✗ Not authenticated with GitHub

Checking n0dom setup...
✗ Repository: not initialized

Summary:
⚠ 4 issue(s) found

Would you like to fix these issues now? [Y/n] y

Git user.email is required for commits
Detected GitHub username: yourname
Use GitHub email: yourname@users.noreply.github.com? [Y/n] y
✓ Git user.email configured

Git user.name is required for commits
Detected GitHub name: Your Name
Use GitHub name: Your Name? [Y/n] y
✓ Git user.name configured

GitHub authentication is required for repository operations
Starting GitHub authentication...
This will open your browser for authentication
# Browser opens for OAuth...
✓ Authenticated with GitHub
  Logged in as: yourname

n0dom repository needs to be initialized

Options:
  [1] Create new dotfiles repository (n0dom init)
  [2] Clone existing repository (n0dom clone)
  [s] Skip for now
Choose [1/2/s]: 1
# Initialization proceeds...

✓ Fix complete! Running doctor again...

N0DOM Doctor - Diagnostics

Checking dependencies...
✓ git: 2.53.0
✓ gh: 2.86.0
✓ yq: installed
✓ meld: installed

Checking Git configuration...
✓ git user.email: yourname@users.noreply.github.com
✓ git user.name: Your Name

Checking GitHub authentication...
✓ Authenticated as: yourname

Checking n0dom setup...
✓ Repository: initialized

Summary:
✓ All checks passed!
```

**Doctor can automatically fix:**
- Missing git user.email and user.name
- GitHub authentication
- Uninitialized repository
- Missing .n0domignore file
- Broken symlinks
- Modified files (not symlinked)
- Missing files (not in home directory)

**Non-interactive mode:**

Use `--check` for CI/CD or scripts:

```bash
$ n0dom doctor --check
# Reports issues and exits with code 1 if problems found
# No prompts, no fixes applied
```

## Configuration

Optional YAML configuration at `~/.config/n0dom/config.yaml`:

```yaml
version: "1.2.0"

repo:
  url: "https://github.com/username/dotfiles"
  branch: "main"
  local_path: "~/.local/share/n0dom/repo"

backup:
  retention_days: 30
  max_backups: 50
  auto_backup: true

sync:
  symlink_mode: true
  conflict_resolver: "auto"
```

### Merge Tool Configuration

The `conflict_resolver` setting controls how conflicts are resolved:

| Value | Behavior |
|-------|----------|
| `auto` | Auto-select first available merge tool |
| `meld` | Use Meld (must be installed) |
| `vimdiff` | Use Vimdiff (must be installed) |
| `code` | Use VS Code (must be installed) |
| `kdiff3` | Use KDiff3 (must be installed) |
| `none` / `manual` | Always show manual menu |

**Supported merge tools:**
- **meld** - Visual merge tool (GUI)
- **vimdiff** - Vim-based diff (CLI)
- **code** - VS Code (GUI)
- **kdiff3** - KDE diff tool (GUI)
- **diffuse** - Graphical diff tool (GUI)

During conflict resolution, you can always:
- Choose `[m]` to open the merge tool
- Choose `[t]` to select a different tool
- Choose `[r/l/s/d]` for manual resolution

## Ignore Patterns

Create `.n0domignore` in your repo root:

```gitignore
# Don't sync these files
.cache/
*.log
*.tmp

# Documentation
README.md
LICENSE

# Secrets (also protected by built-in detection)
.env
*.pem
*.key
```

## Examples

### Daily Workflow

```bash
# Edit your dotfiles
nvim ~/.local/share/n0dom/repo/.bashrc

# Sync everything
n0dom sync "Added new aliases"
```

### New Machine Setup

```bash
# Install n0dom
curl -fsSL https://raw.githubusercontent.com/noeltz/n0dom/main/install.sh | bash

# Authenticate
gh auth login --web

# Clone and activate
n0dom clone username/dotfiles
n0dom sync

# Install packages
n0dom packages import
```

### Safe Sync with Preview

```bash
# See what will change
n0dom sync --dry-run

# If looks good, apply
n0dom sync "Updated configurations"
```

### Recover from Mistake

```bash
# List backups
n0dom restore

# Restore specific backup
n0dom restore 20260219_143022_pre-sync

# Re-sync to continue
n0dom sync
```

### Backup Cleanup

Backups are automatically cleaned based on:
- **Age**: Backups older than `retention_days` (default: 30)
- **Count**: Keeps at most `max_backups` (default: 50)

```bash
# Manual cleanup
n0dom cleanup

# Cleanup runs automatically after:
# - n0dom backup
# - n0dom sync
```

Configure retention in `~/.config/n0dom/config.yaml`:

```yaml
backup:
  retention_days: 30    # Delete backups older than this
  max_backups: 50       # Keep at most this many backups
  auto_backup: true
```

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| "Repository not initialized" | Run `n0dom init` or `n0dom clone <repo>` |
| "GitHub authentication failed" | Run `gh auth login --web` |
| "Failed to acquire lock" | Another n0dom process is running, wait or remove `~/.local/share/n0dom/n0dom.lock` |
| Conflicts not resolving | Install meld: `sudo pacman -S meld` |
| Accidentally deleted files | Run `n0dom restore` to list backups |

### Run Diagnostics

```bash
n0dom doctor
```

This checks:
- All dependencies
- Git configuration
- GitHub authentication
- Repository state
- Backup system
- Broken symlinks

## Comparison

| Feature | n0dom | chezmoi | yadm | bare git |
|---------|-------|---------|------|----------|
| Single command sync | ✓ | ✗ | ✗ | ✗ |
| Two-way merge | ✓ | ✗ | ✗ | ✗ |
| Built-in backups | ✓ | ✗ | ✗ | ✗ |
| Doctor command | ✓ | ✓ | ✗ | ✗ |
| Package tracking | ✓ | ✓ | ✗ | ✗ |
| Machine-specific configs | ✓ | ✓ | ✓ | ✗ |
| Secrets detection | ✓ | ✓ | ✗ | ✗ |
| Interactive conflict resolution | ✓ | ✗ | ✗ | ✗ |
| Rollback on failure | ✓ | ✗ | ✗ | ✗ |

## Dependencies

**Required:**
- `bash` - Shell interpreter
- `git` - Version control
- `github-cli` (gh) - GitHub authentication

**Recommended:**
- `yq` - YAML configuration support
- `meld` - Visual merge tool

**Supported Package Managers:**
- `pacman` - Arch Linux
- `yay` - AUR helper
- `paru` - AUR helper

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing`
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[MIT License](LICENSE)

## Acknowledgments

Inspired by:
- [chezmoi](https://www.chezmoi.io/) - For the excellent templating approach
- [yadm](https://yadm.io/) - For the bare repository concept
- [GNU Stow](https://www.gnu.org/software/stow/) - For symlink farm management

---

<div align="center">

**[Report Bug](https://github.com/noeltz/n0dom/issues)** · **[Request Feature](https://github.com/noeltz/n0dom/issues)**

Made with ❤️ for Arch Linux users

</div>
