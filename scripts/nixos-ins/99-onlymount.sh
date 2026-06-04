#!/usr/bin/env bash
## 99-onlymount.sh — Mount existing btrfs subvolumes (no subvolume creation)
## Usage: ./99-onlymount.sh [DISK] [SWAP_SIZE]
## Defaults: /dev/sda, 4g
## Use this when subvolumes already exist but need to remount (e.g. after reboot)
set -euo pipefail

DISK="${1:-/dev/sda}"
SWAP_SIZE="${2:-4g}"

partition_path() {
    local disk="$1"
    local number="$2"

    if [[ "${disk}" =~ [0-9]$ ]]; then
        printf '%sp%s\n' "${disk}" "${number}"
    else
        printf '%s%s\n' "${disk}" "${number}"
    fi
}

ROOT_PART="$(partition_path "${DISK}" 2)"
ESP_PART="$(partition_path "${DISK}" 1)"

if [[ ! -b "${ROOT_PART}" ]]; then
    echo "Error: ${ROOT_PART} not found"
    exit 1
fi

if [[ ! -b "${ESP_PART}" ]]; then
    echo "Error: ${ESP_PART} not found"
    exit 1
fi

echo ">>> Mounting subvolumes (compress=zstd, ssd)..."
MOUNT_OPTS="compress=zstd,ssd,compress-force=zstd"

mount -o "subvol=@,${MOUNT_OPTS}" "${ROOT_PART}" /mnt
mkdir -p /mnt/{home,nix,boot,swap}

mount -o "subvol=@home,${MOUNT_OPTS}" "${ROOT_PART}" /mnt/home
mount -o "subvol=@nix,${MOUNT_OPTS}" "${ROOT_PART}" /mnt/nix
mount -o "subvol=@swap,ssd" "${ROOT_PART}" /mnt/swap

echo ">>> Mounting EFI partition..."
mount "${ESP_PART}" /mnt/boot

echo ">>> Activating swap file..."
swapon /mnt/swap/swapfile 2>/dev/null || {
    echo "Swap file not found, creating (${SWAP_SIZE})..."
    btrfs filesystem mkswapfile --size "${SWAP_SIZE}" /mnt/swap/swapfile
    swapon /mnt/swap/swapfile
}

echo ""
echo ">>> Mount summary:"
df -h /mnt /mnt/home /mnt/nix /mnt/boot
swapon --show
echo ""
echo "Next: run 04-config.sh"
