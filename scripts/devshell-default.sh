#!/usr/bin/env bash
set -euo pipefail

export NIX_CONFIG='extra-experimental-features = nix-command flakes
accept-flake-config = true
substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/ https://mirrors.ustc.edu.cn/nix-channels/store'

exec nix develop
