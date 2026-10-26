# NixOS Bare-Metal Installation with btrfs (Ventoy)

Quick reference for installing NixOS from a Ventoy USB onto bare metal with btrfs.

## Ventoy Boot Mode Selection

When booting NixOS ISO via Ventoy, choose **Normal mode** first. If it hangs, try **grub2 mode**. Avoid **memdisk** (loads entire ISO into RAM — too much for old hardware).

For older hardware (e.g., Lenovo E41):
- Use **UEFI mode** if available — NixOS ISO's UEFI support is more complete
- If only Legacy BIOS available, **grub2 mode** has higher success rate
- If boot hangs after selecting kernel, try adding `nomodeset` at the boot prompt

## Kernel Selection

Choose **lts** kernel for old hardware. Newer kernels (6.x) don't add value for older platforms and may introduce compatibility issues.

## parted vs mkfs: Type Markers Are Cosmetic

`parted ... mkpart primary ext4 ...` — the `ext4` in parted is just a **type marker**, not the actual filesystem. parted doesn't recognize `btrfs` as a type name. Write anything (`ext4`, `primary`, or omit it). The actual filesystem is determined by `mkfs.btrfs` later.

## btrfs Partition + Subvolume Setup (UEFI)

```bash
# Partition (ESP + main)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

# Format
mkfs.fat -F32 /dev/sda1
mkfs.btrfs -L nixos /dev/sda2

# Create subvolumes
mount /dev/sda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@swap
umount /mnt

# Remount with subvolumes + compression
mount -o subvol=@,compress=zstd /dev/sda2 /mnt
mkdir -p /mnt/{home,nix,boot,swap}
mount -o subvol=@home,compress=zstd /dev/sda2 /mnt/home
mount -o subvol=@nix,compress=zstd /dev/sda2 /mnt/nix
mount -o subvol=@swap /dev/sda2 /mnt/swap
mount /dev/sda1 /mnt/boot

# Swap file
btrfs filesystem mkswapfile --size 4g /mnt/swap/swapfile
swapon /mnt/swap/swapfile
```

## Pitfalls

### "Inappropriate ioctl for device" on btrfs subvolume create

**Cause**: `mkfs.btrfs` didn't succeed (or wasn't run), so the partition isn't actually btrfs.

**Fix**: Re-run with `-f` (force):
```bash
mkfs.btrfs -f /dev/sda2
```
Then verify: `btrfs filesystem show /mnt` should show btrfs info.

### Subvolume names with @ prefix

The `@`, `@home`, `@nix`, `@swap` naming convention is a community standard (popularized by Timeshift). Not required by btrfs, but widely used for snapshot tools. The `@` prefix is just a naming convention — btrfs doesn't treat it specially.

### SSD vs HDD mount options

- SSD: add `ssd` to mount options
- HDD: remove `ssd`, optionally add `discard=async`
- Old laptops without SSD: just use `compress=zstd` without `ssd`

### Legacy BIOS (no ESP)

If `ls /sys/firmware/efi` doesn't exist, skip the ESP partition. Use `msdos` label instead of `gpt`, and only create swap + root partitions. No separate `/boot` mount needed.
