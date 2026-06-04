#!/usr/bin/env bash
## 02-partition.sh — GPT partition + format (ESP + btrfs)
## Usage: ./02-partition.sh [DISK]
## Default: /dev/sda
set -euo pipefail

DISK="${1:-/dev/sda}"

partition_path() {
    local disk="$1"
    local number="$2"

    if [[ "${disk}" =~ [0-9]$ ]]; then
        printf '%sp%s\n' "${disk}" "${number}"
    else
        printf '%s%s\n' "${disk}" "${number}"
    fi
}

ESP_PART="$(partition_path "${DISK}" 1)"
ROOT_PART="$(partition_path "${DISK}" 2)"

if [[ ! -b "${DISK}" ]]; then
    echo "Error: ${DISK} is not a block device"
    exit 1
fi

echo "========================================="
echo "  About to partition ${DISK}"
echo "  !! All data will be erased !!"
echo "========================================="
read -rp "Confirm? (y/N): " confirm
[[ "${confirm}" == [yY] ]] || exit 0

echo ">>> Creating GPT partition table..."
parted "${DISK}" -- mklabel gpt

echo ">>> Creating EFI system partition (1GiB)..."
parted "${DISK}" -- mkpart ESP fat32 1MiB 1024MiB
parted "${DISK}" -- set 1 esp on

echo ">>> Creating primary partition (remaining space)..."
parted "${DISK}" -- mkpart primary 1024MiB 100%

echo ">>> Waiting for partition devices..."
if command -v partprobe >/dev/null 2>&1; then
    partprobe "${DISK}"
fi
if command -v udevadm >/dev/null 2>&1; then
    udevadm settle
fi

if [[ ! -b "${ESP_PART}" ]]; then
    echo "Error: ${ESP_PART} not found after partitioning"
    exit 1
fi

if [[ ! -b "${ROOT_PART}" ]]; then
    echo "Error: ${ROOT_PART} not found after partitioning"
    exit 1
fi

echo ">>> Formatting EFI partition..."
mkfs.fat -F32 "${ESP_PART}"

echo ">>> Formatting btrfs partition..."
mkfs.btrfs -L nixos "${ROOT_PART}"

echo ""
echo ">>> Partitioning done:"
lsblk "${DISK}"
echo ""
echo "Next: run 03-subvolumes.sh"
