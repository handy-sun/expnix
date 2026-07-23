#!/usr/bin/env bash
set -euo pipefail

export NIX_CONFIG='extra-experimental-features = nix-command flakes
accept-flake-config = true
substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/ https://mirrors.ustc.edu.cn/nix-channels/store'

configure_trusted_substituters() {
    local nix_conf=/etc/nix/nix.conf
    local trusted_substituters="extra-trusted-substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/ https://mirrors.ustc.edu.cn/nix-channels/store"
    local config_changed=false
    local sudo=""

    ## Nix daemon settings require root; client settings come from NIX_CONFIG.
    if [ "$(id -u)" -ne 0 ]; then
        if ! command -v sudo >/dev/null 2>&1; then
            echo "Need root to write $nix_conf, but sudo not found." >&2
            return 1
        fi
        sudo=sudo
    fi

    if [ ! -f "$nix_conf" ] || ! grep -Fxq "$trusted_substituters" "$nix_conf"; then
        $sudo tee -a "$nix_conf" >/dev/null << EOF
${trusted_substituters}
EOF
        config_changed=true
    fi

    if ! grep -Fxq "$trusted_substituters" "$nix_conf"; then
        echo "Failed to configure $nix_conf" >&2
        return 1
    fi

    if [ "$config_changed" = true ] && command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet nix-daemon.service; then
        $sudo systemctl restart nix-daemon.service
    fi

    echo "nix.conf configured: $nix_conf"
    return 0
}

configure_trusted_substituters

nix eval .#systemConfigs.debnsm.config.build.toplevel

exec nix develop .#sysmgr
