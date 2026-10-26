---
name: shell-scripting
description: Guidelines for writing shell scripts — style, output language, structure, and common patterns.
tags: [bash, scripting, shell, cli, nixos]
---

# Shell Scripting Guidelines

## Critical User Preference

**All printed output MUST be in English.** This includes:
- `echo` statements
- `read` prompts
- Error messages
- Success/completion messages
- Warning messages

Comments should also be in English (per Nix code convention: `##` for explanatory comments that will never be uncommented).

## Script Structure

```bash
#!/usr/bin/env bash
## script-name.sh — Brief description in English
## Usage: ./script-name.sh [OPTIONS] [ARGS]
set -euo pipefail
```

### Header conventions
- Line 1: shebang `#!/usr/bin/env bash`
- Line 2+: `##` comment with purpose and usage
- `set -euo pipefail` immediately after

### Progress messages
Use `>>>` prefix for step-by-step output:
```bash
echo ">>> Starting operation..."
echo ">>> Operation complete"
```

### Error messages
Plain text, no prefix:
```bash
echo "Error: device not found"
echo "Warning: missing entry in config"
```

## Common Patterns

### Parameters with defaults
```bash
DISK="${1:-/dev/sda}"
SWAP_SIZE="${2:-4g}"
```

### Confirmation before destructive operations
```bash
echo "========================================="
echo "  About to format ${DISK}"
echo "  !! All data will be erased !!"
echo "========================================="
read -rp "Confirm? (y/N): " confirm
[[ "${confirm}" == [yY] ]] || exit 0
```

### Error handling with message
```bash
command || { echo "Command failed"; exit 1; }

if [[ ! -b "${DISK}" ]]; then
    echo "Error: ${DISK} is not a block device"
    exit 1
fi
```

### Section completion summary
```bash
echo ""
echo ">>> Summary:"
echo "    File: /path/to/output"
echo ""
echo "Next: run next-step.sh"
```

## Numbered Script Sequences

For multi-step workflows, use numbered scripts:
```
01-step-one.sh
02-step-two.sh
03-step-three.sh
```

Each script should:
- Be independently runnable with sensible defaults
- Print "Next: run NNN-xxx.sh" at the end
- Validate prerequisites (check if previous step's output exists)

## Reference Examples

See `references/nixos-install-scripts-example.md` for a complete multi-step NixOS installation workflow demonstrating conditional args, create-vs-mount separation, and post-generation validation.

## NixOS-Specific Patterns

### Channel mirror setup
```bash
nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixos-unstable nixos
nix-channel --update
```

### Chroot operations
```bash
nixos-enter -c "useradd username -m -G wheel"
nixos-enter -c "passwd username"
```

### Config generation with checks
```bash
nixos-generate-config --root /mnt
if ! grep -q 'subvol=@' /mnt/etc/nixos/hardware-configuration.nix; then
    echo "Warning: no btrfs subvolume entries found, please check manually"
fi
```
