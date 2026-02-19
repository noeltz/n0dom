# AGENTS.md - N0DOM Development Guidelines

This document provides guidance for AI coding agents working on the n0dom codebase.

## Project Overview

n0dom is a single-file bash CLI application for managing dotfiles on Arch Linux. It provides two-way sync between a local repository and GitHub, with symlink management, automatic backups, and conflict resolution.

## Commands

### Syntax Check
```bash
bash -n n0dom && echo "Syntax OK"
bash -n install.sh && echo "Syntax OK"
```

### Shellcheck (Lint)
```bash
shellcheck n0dom
shellcheck install.sh
```

### Manual Testing
```bash
./n0dom help
./n0dom doctor
./n0dom status
./n0dom sync --dry-run
```

### Install Locally
```bash
cp n0dom ~/.local/bin/n0dom && chmod +x ~/.local/bin/n0dom
```

## Code Style Guidelines

### Bash Strict Mode
```bash
#!/usr/bin/env bash
set -euo pipefail
```
For install.sh, use `set -e` only.

### Constants
- Use `readonly` for all constants at the top of the file
- Prefix constants with `N0DOM_`
- Group related constants with section headers

### Section Headers
```bash
# ============================================
# SECTION NAME
# ============================================
```

### Function Naming
- Use snake_case: `track_file`, `create_backup`
- Use verb_noun pattern: `show_status`, `run_diagnostics`
- Print functions: `print_success`, `print_error`, `print_info`

### Variable Naming
- Use snake_case for all variables
- Use `local` for function-scoped variables
- Quote all variable expansions: `"$variable"`

### Error Handling

**Exit Codes:**
- 0: Success
- 1: General error / unknown command
- 2: Missing dependencies
- 3: GitHub authentication failed
- 4: Repository operation failed
- 5: Configuration/sync error
- 6: Backup/restore failed

**Pattern:**
```bash
cd "$N0DOM_REPO_PATH" || exit 5

if ! command -v required_tool &> /dev/null; then
    print_error "Required tool not found"
    exit 2
fi
```

**Arithmetic with set -e:**
```bash
((counter++)) || true
((total--)) || true
```

### Conditional Tests
- Use `[[ ]]` instead of `[ ]` for string/file tests
- Quote variables: `[[ "$var" == "value" ]]`

### Loops
```bash
while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    # process file
done < <(git ls-files)
```

### Echo and Colors
- Use `echo -e` for colored output
- Use print functions for consistent output
```bash
print_success "Operation completed"
print_error "Something failed" >&2
```

### Trap and Cleanup
```bash
cleanup() {
    release_lock
    if [[ -n "$backup_id" ]]; then
        restore_backup "$backup_id"
    fi
}
trap cleanup EXIT
```

**Note:** Local variables aren't accessible in trap. Use global-ish names:
```bash
N0DOM_SYNC_BACKUP_ID=""
N0DOM_SYNC_ROLLBACK="false"
```

### Confirmation Prompts
```bash
if confirm_action "Proceed with sync?" "n"; then
    # user confirmed
fi
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `main()` | Entry point, command routing |
| `perform_two_way_sync()` | Core sync operation |
| `create_backup()` | Create timestamped backup |
| `run_diagnostics()` | Doctor command |
| `confirm_action()` | User confirmation with --force |
| `safe_remove()` | Logging wrapper for rm -rf |
| `is_ignored()` | Check if file matches .n0domignore |

## Common Pitfalls

1. **Arithmetic exit codes:** `((i++))` returns non-zero when i goes 0->1. Use `((i++)) || true`

2. **Local in trap:** Local variables aren't accessible in trap. Use global-ish names.

3. **Echo colors:** Must use `echo -e` for ANSI escape codes.

4. **Git in empty repo:** Check for commits first: `git rev-parse --verify HEAD &> /dev/null`

5. **Quote variables:** Always quote: `"$file"`, `"$path"`

## Testing Checklist

1. `bash -n n0dom` - syntax check
2. `n0dom help` - help displays
3. `n0dom doctor` - diagnostics work
4. `n0dom status` - status shows correctly
5. `n0dom sync --dry-run` - preview works
