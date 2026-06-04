#!/usr/bin/env bash
## 04-config.sh — Generate hardware config and write configuration.nix
## Usage: ./04-config.sh [HOSTNAME]
## Default hostname: nixos
set -euo pipefail

HOSTNAME="${1:-nixos}"

echo ">>> Generating hardware configuration..."
nixos-generate-config --root /mnt

echo ">>> Backing up original configuration.nix..."
cp /mnt/etc/nixos/configuration.nix /mnt/etc/nixos/configuration.nix.bak

echo ">>> Writing configuration.nix..."
cat > /mnt/etc/nixos/configuration.nix <<'NIXEOF'
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  ## Bootloader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ## Hostname
NIXEOF

cat >> /mnt/etc/nixos/configuration.nix <<NIXEOF
  networking.hostName = "${HOSTNAME}";
NIXEOF

cat >> /mnt/etc/nixos/configuration.nix <<'NIXEOF'

  ## Wireless (use nmtui after reboot)
  networking.networkmanager.enable = true;

  ## Timezone
  time.timeZone = "Asia/Shanghai";

  ## Locale
  i18n.defaultLocale = "zh_CN.UTF-8";

  ## Base packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
  ];

  ## Firewall
  networking.firewall.enable = false;

  ## Swap tuning
  boot.kernel.sysctl."vm.swappiness" = 10;

  system.stateVersion = "25.05";
}
NIXEOF

echo ">>> Checking hardware-configuration.nix for subvolumes and swap..."
HWCONF="/mnt/etc/nixos/hardware-configuration.nix"

if ! grep -q 'subvol=@' "${HWCONF}"; then
    echo "Warning: no btrfs subvolume entries found in hardware-configuration.nix, please check manually"
fi

if ! grep -q 'swapfile' "${HWCONF}"; then
    echo "Warning: no swap entry found in hardware-configuration.nix, please check manually"
fi

echo ""
echo ">>> Config files written:"
echo "    /mnt/etc/nixos/configuration.nix"
echo "    /mnt/etc/nixos/hardware-configuration.nix"
echo ""
echo ">>> Review recommended:"
echo "    nano /mnt/etc/nixos/configuration.nix"
echo "    nano /mnt/etc/nixos/hardware-configuration.nix"
echo ""
echo "Next: run 05-install.sh"
