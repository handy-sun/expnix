#!/usr/bin/env bash
## 05-install.sh — Install NixOS and create user
## Usage: ./05-install.sh [USERNAME]
set -euo pipefail

echo "========================================="
echo "  About to install NixOS"
echo "  You will be prompted for root password"
echo "========================================="
read -rp "Confirm? (y/N): " confirm
[[ "${confirm}" == [yY] ]] || exit 0

echo ">>> Installing system..."
nixos-install --option substituters https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store

echo ">>> Creating user..."
USER_NAME="${1:-qi}"

nixos-enter -c "useradd ${USER_NAME} -m -G wheel"
echo ">>> Set user password:"
nixos-enter -c "passwd ${USER_NAME}"

echo ""
echo "========================================="
echo "  Installation complete!"
echo "  Remove USB and reboot"
echo "========================================="
echo ""
echo "After first boot:"
echo "  1. nmtui                    — connect to WiFi"
echo "  2. sudo nixos-rebuild switch — update system"
