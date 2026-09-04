#!/usr/bin/env bash
set -euo pipefail

export NIX_CONFIG='extra-experimental-features = nix-command flakes
accept-flake-config = true
substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/ https://mirrors.ustc.edu.cn/nix-channels/store'

configure_nix_daemon_conf() {
    local nix_conf=/etc/nix/nix.conf
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

    ## Lines to ensure in the daemon config, mirroring lib/nix-common.nix until
    ## system-manager replaces /etc/nix/nix.conf after the first switch.
    ## trusted-users must include the invoking user: system-manager hardcodes
    ## --extra-substituters/--extra-trusted-public-keys for cache.numtide.com
    ## in its internal nix build, and the daemon drops restricted settings
    ## passed by untrusted users.
    local lines=(
        "extra-trusted-substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/ https://mirrors.ustc.edu.cn/nix-channels/store"
        "trusted-users = root $(id -un)"
    )
    local line
    for line in "${lines[@]}"; do
        if [ ! -f "$nix_conf" ] || ! grep -Fxq "$line" "$nix_conf"; then
            $sudo tee -a "$nix_conf" >/dev/null << EOF
${line}
EOF
            config_changed=true
        fi
    done

    for line in "${lines[@]}"; do
        if ! grep -Fxq "$line" "$nix_conf"; then
            echo "Failed to configure $nix_conf" >&2
            return 1
        fi
    done

    if [ "$config_changed" = true ] && command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet nix-daemon.service; then
        $sudo systemctl restart nix-daemon.service
    fi

    echo "nix.conf configured: $nix_conf"
    return 0
}

configure_nix_daemon_conf

# nix eval .#systemConfigs.debnsm.config.build.toplevel

exec nix develop .#sysmgr
