#!/usr/bin/env bash
set -euo pipefail

# dotzsh_tide is a fish function, not a standalone binary — must invoke via fish
fish -c 'dotzsh_tide lean2 && dotzsh_tide set-vi-icon && dotzsh_tide ar private_mode shlvl proxy'

mkdir -p ~/.local/share/npm-global
mkdir -p ~/.local/bin
# test -d ~/.ssh && ls -lh ~/.ssh || mkdir -p ~/.ssh

gh auth login -p ssh

mkdir -p ~/.config/nix
NIX_CONF="${HOME}/.config/nix/nix.conf"
TOKEN_TMP="$(mktemp)"
NIX_CONF_TMP="$(mktemp)"
trap 'rm -f "${TOKEN_TMP}" "${NIX_CONF_TMP}"' EXIT

touch "${NIX_CONF}"
chmod 600 "${NIX_CONF}"
gh auth token > "${TOKEN_TMP}"
chmod 600 "${NIX_CONF_TMP}"
awk -v token="$(<"${TOKEN_TMP}")" '
    BEGIN { written = 0 }
    /^access-tokens = github.com=/ {
        if (!written) {
            print "access-tokens = github.com=" token
            written = 1
        }
        next
    }
    { print }
    END {
        if (!written) {
            print "access-tokens = github.com=" token
        }
    }
' "${NIX_CONF}" > "${NIX_CONF_TMP}"
install -m 600 "${NIX_CONF_TMP}" "${NIX_CONF}"

npm i -g @anthropic-ai/claude-code@latest
npm i -g @openai/codex@latest
npm i -g --ignore-scripts @earendil-works/pi-coding-agent
npm i -g opencode-ai
npm i -g oh-my-opencode
curl -fsSL https://antigravity.google/cli/install.sh | bash

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain 1.94.0

vim +PlugInstall +qall

nvim --headless -c "lua require('user.bootstrap')()"

## daily update
# vim +PlugUpdate +qall
# nvim --headless -i NONE '+lua require("nvim-treesitter").install(require("core.settings").treesitter_deps):wait(300000)' '+qa'
## donnot suggest
# nvim --headless -i NONE '+lua require("nvim-treesitter").install("all"):wait(300000)' '+qa'
### https://github.com/martanne/abduco
# mkdir -p ~/.config/quickshell && ln -sfnv ~/.config/noctalia-shell ~/.config/quickshell/noctalia-shell
