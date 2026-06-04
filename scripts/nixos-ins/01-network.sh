#!/usr/bin/env bash
## 01-network.sh — Connect to WiFi (if needed) and switch nix channel to USTC mirror
## Usage: ./01-network.sh [SSID] [PASSWORD]
## SSID/PASSWORD are only required when no network is available
set -euo pipefail

echo ">>> Checking network connectivity..."
if ping -c 1 -W 3 baidu.com &>/dev/null; then
    echo ">>> Network is already up (wired?), skipping WiFi setup"
else
    if [[ $# -lt 2 ]]; then
        echo "No network detected. Usage: $0 <SSID> <PASSWORD>"
        exit 1
    fi

    SSID="$1"
    PASSWORD="$2"

    echo ">>> Starting wpa_supplicant..."
    systemctl start wpa_supplicant

    echo ">>> Connecting to WiFi: ${SSID}..."
    wpa_cli <<EOF
add_network
set_network 0 ssid "${SSID}"
set_network 0 psk "${PASSWORD}"
enable_network 0
save_config
quit
EOF

    echo ">>> Waiting for IP address..."
    sleep 5

    echo ">>> Checking network..."
    ip -4 a l
    ping -c 3 baidu.com || { echo "WiFi connection failed"; exit 1; }
fi

echo ">>> Switching nix channel to USTC mirror..."
nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixos-unstable nixos
nix-channel --update

echo ">>> Network setup complete"
