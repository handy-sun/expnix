# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NixOS + nix-darwin + home-manager multi-system configuration. Manages a Linux VM (OrbStack), WSL, and macOS machine from a single flake.

## Key Commands

```bash
just switch         # Build & activate config (nh os/darwin switch .)
just nixfmt         # Format all .nix files with nixfmt
just upc-nix        # Update nixpkgs, nix-darwin, nixos-wsl, home-manager, rust-overlay inputs
just upc-my         # Update personal dotfile inputs (my-dotzsh, my-dotfiles, etc.)
just repl           # Open nix repl on the flake
just repl-flake    # Open nix repl on nixpkgs
just show-conf      # Show Nix configuration
just preshell       # Start dev shell with nh + git available
just setup-hook     # Set up git hooks (pre-commit)
```

For `nix flake check` the formatter is `nixfmt`, no extra checks.

## Architecture

```
flake.nix           → defines 3 outputs: nixosConfigurations, darwinConfigurations, homeConfigurations
lib/
  mksystem.nix      → mkSystem hostName { system, isDarwin?, isWSL? }: creates osSystem or darwinSystem
  mkhome.nix        → mkHome system { }: standalone home-manager for non-NixOS Linux
  vars.nix          → user="qi", lang="zh_CN.UTF-8", commonEnv, homeEnv
  utils.nix         → relativeToRoot (path helpers), scanPaths (auto-import .nix files in dir)
hosts/<name>/       → Per-host config. Each imports machine base + nixos modules + overlays via relativeToRoot
machines/           → Reusable base configs: nix-core.nix (Nix settings), darwin-base.nix, wsl-base.nix, orb-base.nix
nixos/              → NixOS-only modules. default.nix uses scanPaths to auto-import *.nix (services.nix etc.)
modules/            → Custom reusable modules (sing-box)
overlays/           → Nixpkgs overlays (beszel, deno)
home/               → Home-manager config shared across all systems
  tui/              → Sub-modules: shells, editor, git, ssh, xdg, yazi, misc
```

### How `mkSystem` works

`mkSystem hostName { system, isDarwin?, isWSL? }` automatically:
1. Selects `nixosSystem` or `darwinSystem` based on `isDarwin`
2. Loads `nix-core.nix` (Nix settings), `hosts/<hostName>/` (host config), rust overlay
3. Wires up home-manager with `./home` as user config
4. Conditionally adds `nixos-wsl` module if `isWSL`

### `scanPaths` pattern

Import directories that use `scanPaths ./.` (like `nixos/` and `home/tui/`) auto-import all `.nix` files except `default.nix` — drop a new file in and it's automatically included.

## Key Design Decisions

- Uses `nh` (Nix Helper) for switching, not raw `nixos-rebuild`/`darwin-rebuild`
- On macOS, `nix.enable = false` because Determinate Nix is used instead
- Home-manager `stateVersion = "25.11"`, NixOS `stateVersion = "26.05"`
- System user = `qi`, locale = `zh_CN.UTF-8`, timezone = `Asia/Shanghai`
- Uses Chinese mirrors for Nix substituters, Rust, pip, and homebrew
