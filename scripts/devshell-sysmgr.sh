#!/usr/bin/env bash
set -euo pipefail

inject_nix_conf() {
    local nix_conf=/etc/nix/nix.conf
    local user_name sudo=""
    user_name=$(id -un)
    if [ -z "$user_name" ]; then
        echo "Current user_name is null!" >&2
        return 1
    fi

    ## write to /etc/nix/nix.conf need root; no root need sudo
    if [ "$(id -u)" -ne 0 ]; then
        if ! command -v sudo >/dev/null 2>&1; then
            echo "Need root to write $nix_conf, but sudo not found." >&2
            return 1
        fi
        sudo=sudo
    fi

    if [ ! -f "$nix_conf" ] || ! grep -Eq 'trusted-users|experimental-features' "$nix_conf"; then
        $sudo tee -a "$nix_conf" >/dev/null << EOF
accept-flake-config = true
experimental-features = nix-command flakes
substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/ https://mirrors.ustc.edu.cn/nix-channels/store/ https://cache.nixos.org/
trusted-users = root ${user_name}
EOF
    fi

    ## Check writed
    if ! grep -Eq '^experimental-features' "$nix_conf" || ! grep -Eq '^trusted-users' "$nix_conf"; then
        echo "Failed to configure $nix_conf" >&2
        return 1
    fi
    echo "nix.conf configured: $nix_conf"
    return 0
}

inject_nix_conf

nix eval --experimental-features 'nix-command flakes' .#systemConfigs.debnsm.config.build.toplevel

nix develop --experimental-features 'nix-command flakes' .#sysmgr
