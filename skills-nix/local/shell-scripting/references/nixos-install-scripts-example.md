# NixOS Installation Scripts — Example Multi-Step Workflow

A set of numbered bash scripts for NixOS installation on bare metal (UEFI + btrfs).

## File Structure

```
scripts/
  01-network.sh      — WiFi connection (conditional) + nix channel mirror
  02-partition.sh    — GPT partition + format (ESP + btrfs)
  03-subvolumes.sh   — Create btrfs subvolumes + mount + swap
  03-onlymount.sh    — Mount existing subvolumes only (skip creation)
  04-config.sh       — Generate hardware config + write configuration.nix
  05-install.sh      — nixos-install + user creation
```

## Key Patterns Demonstrated

### Conditional argument requirement
```bash
# Only require WiFi args when network is down
if ping -c 1 -W 3 baidu.com &>/dev/null; then
    echo ">>> Network is already up, skipping WiFi setup"
else
    if [[ $# -lt 2 ]]; then
        echo "No network detected. Usage: $0 <SSID> <PASSWORD>"
        exit 1
    fi
    # ... connect WiFi
fi
```

### Create vs Mount separation
- `03-subvolumes.sh` — full workflow: create subvolumes + mount
- `03-onlymount.sh` — remount only, auto-creates swap if missing

Useful when installation requires reboot mid-process.

### Post-generation validation
```bash
nixos-generate-config --root /mnt
if ! grep -q 'subvol=@' /mnt/etc/nixos/hardware-configuration.nix; then
    echo "Warning: no btrfs subvolume entries found, please check manually"
fi
```

## README Template

```markdown
## Run sequentially after booting from USB

\`\`\`
./01-network.sh                    # wired network, no args needed
./01-network.sh MyWiFi password123 # wireless, provide SSID and password
./02-partition.sh /dev/sda         # default: /dev/sda, can be omitted
./03-subvolumes.sh /dev/sda 4g     # swap size default: 4g, can be omitted
./03-onlymount.sh /dev/sda 4g      # remount existing subvolumes
./04-config.sh nixos               # hostname default: nixos
./05-install.sh handy              # username default: handy
\`\`\`
```
