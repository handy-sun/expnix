# Usage Examples

---

## Run sequentially after booting from USB

```
./01-network.sh                    # wired network, no args needed
./01-network.sh MyWiFi password123 # wireless, provide SSID and password
./02-partition.sh /dev/sda         # default: /dev/sda, can be omitted
./03-subvolumes.sh /dev/sda 4g     # swap size default: 4g, can be omitted
./03-onlymount.sh /dev/sda 4g      # remount existing subvolumes (skip creation)
./04-config.sh nixos               # hostname default: nixos
./05-install.sh handy              # username default: handy
```

---

## Highlights

- `01-network.sh` auto-detects existing network; WiFi args only required when offline
- `02-partition.sh` prompts for confirmation before partitioning to prevent accidents
- `03-subvolumes.sh` creates subvolumes and mounts them with btrfs compression and SSD optimizations
- `03-onlymount.sh` remounts existing subvolumes only, auto-creates swap file if missing
- `04-config.sh` verifies subvolumes and swap are correctly detected in hardware-configuration.nix
- `05-install.sh` guides user creation and password setup after installation
