#!/usr/bin/env bash
## 05-install.sh — Install NixOS and enter the installed system
## Usage: ./05-install.sh
set -euo pipefail

echo "========================================="
echo "  About to install NixOS"
echo "  You will be prompted for root password"
echo "========================================="
read -rp "Confirm? (y/N): " confirm
[[ "${confirm}" == [yY] ]] || exit 0

echo ">>> Installing system..."
nixos-install --option substituters https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store

echo ">>> Entering installed system..."
echo "Create users and set passwords inside the shell, then run: exit"
nixos-enter

echo ""
echo "========================================="
echo "  Installation complete!"
echo "  Remove USB and reboot"
echo "========================================="
echo ""
echo "After first boot:"
echo "  1. nmtui                    — connect to WiFi"
echo "  2. sudo nixos-rebuild switch — update system"
