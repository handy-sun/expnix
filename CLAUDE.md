# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NixOS + nix-darwin + home-manager multi-system configuration. Manages 3 machines from a single flake:

| Host | Type | Arch | Notes |
|------|------|------|-------|
| expnix | OrbStack NixOS | aarch64-linux | Primary dev machine; sing-box with auto config generation; custom DNS |
| nixwsl | WSL2 NixOS | x86_64-linux | Windows subsystem; CUDA support; beszel-agent monitoring |
| handyMini | nix-darwin | aarch64-darwin | Determinate Nix; homebrew for GUI apps; multiple launchd agents |

## Key Commands

```bash
just switch           # Build & activate config (nh os/darwin switch .) — platform-aware
just switch-home      # Only switch home-manager, skip system (nh home switch .)
just nixfmt           # Format all .nix files with nixfmt (fd -e nix -X nixfmt)
just upc-nix          # Update nixpkgs, nix-darwin, nixos-wsl, home-manager, rust-overlay inputs (+ commit)
just upc-my           # Update personal dotfile inputs (my-dotzsh, my-dotfiles, etc.) (+ commit)
just up-my            # Update personal inputs without committing
just repl             # Open nix repl on the flake (nix repl .)
just repl-flake       # Open nix repl on nixpkgs (nix repl -f flake:nixpkgs)
just repl-pkgs        # Open nix repl on <nixpkgs>
just repl-nh          # Open nh repl (platform-aware: nh os/darwin repl .)
just show-conf        # Show Nix configuration
just preshell         # Start dev shell with nh + git available
just setup-hook       # Set up git hooks (pre-commit)
just history          # Show system profile history
just current-sys      # Show the running /run/current-system symlink target
just nixinfo          # Diagnostic: nix-info -m
just query-all <pkg>  # Why is this package in the current system?
just query-depends <pkg>      # NixOS: trace why a package depends on toplevel
just query-dep-home <pkg>     # Same for home-manager activation package
```

Aliases: `s` = switch, `f` = nixfmt, `sh` = switch-home.

The `switch` recipe has separate `[linux]` and `[macos]` variants — it auto-detects the platform.

For `nix flake check` the formatter is `nixfmt`, no extra checks.

## CI

GitHub Actions workflow at `.github/workflows/ci.yml`:

- **Trigger**: push/PR to `main` or `dev*` branches, ignores `**.md`, `Justfile`, `.gitignore`, `LICENSE`
- **Stage 1 (flake-check)**: `nix flake check` + `statix check` (only errors fail, warnings are OK)
- **Stage 2 (build matrix)**: dry-run build on native platforms — needs stage 1 to pass
  - expnix → `ubuntu-24.04-arm` (aarch64-linux)
  - nixwsl → `ubuntu-latest` (x86_64-linux)
  - handyMini → `macos-14` (aarch64-darwin)
  - home → `ubuntu-latest` (x86_64-linux, homeConfigurations.qi)

Garnix CI is also configured via `garnix.yaml` — builds all configurations on all systems.

## Architecture

```
flake.nix           → defines 3 outputs: nixosConfigurations, darwinConfigurations, homeConfigurations
lib/
  mksystem.nix      → mkSystem hostName { system, isDarwin?, isWSL?, profileLevel? }: creates osSystem or darwinSystem
  mkhome.nix        → mkHome system { }: standalone home-manager for non-NixOS Linux
  vars.nix          → user="qi", lang="zh_CN.UTF-8", commonEnv, homeEnv, profileLevel defaults
  utils.nix         → relativeToRoot (path helpers), scanPaths (auto-import .nix files in dir)
hosts/<name>/       → Per-host config. Each imports machine base + nixos modules + overlays via relativeToRoot
machines/           → Reusable base configs:
                      nix-core.nix — shared Nix settings (substituters, GC, allowUnfree, hostName)
                      darwin-base.nix — macOS: homebrew mirrors, fonts, system packages, homebrew casks
                      wsl-base.nix — WSL: defaultUser, startMenuLaunchers, stateVersion
                      orb-base.nix — OrbStack LXC: systemd watchdog tweaks, uid=501, systemd-networkd
nixos/              → NixOS-only modules. default.nix uses scanPaths to auto-import *.nix (services.nix etc.)
                      Disables upstream services.networking.sing-box in favor of the custom module.
modules/            → Custom reusable modules:
                      sing-box — with configGeneration sub-option
                      caddy-webdav — WebDAV server module with launchd support
overlays/           → Nixpkgs overlays:
                      beszel.nix — adds "testing" tag, skips GPU tests
                      deno.nix — filters out a broken patch (fd331552)
                      direnv.nix — darwin workaround
home/               → Home-manager config shared across all systems. Imports my-dotzsh + my-nvimdots.
  tui/              → Sub-modules (auto-imported via scanPaths): shells, editor, git, ssh, xdg, yazi, misc
    packages/       → TUI packages split by profile level:
                      base.nix — always included: essential terminal tools
                      advanced.nix — gated by profileLevel.tuiAdvanced
                      optional.nix — rust toolchain, gated by profileLevel.tuiOptional
                      platform.nix — platform-specific packages (Linux/Darwin)
  gui/              → GUI packages (auto-imported via scanPaths):
    packages/       → GUI packages split by profile level:
                      base.nix — gated by profileLevel.guiBase
                      heavy.nix — gated by profileLevel.guiHeavy
```

### How `mkSystem` works

`mkSystem hostName { system, isDarwin?, isWSL?, profileLevel? }` automatically:
1. Selects `nixosSystem` or `darwinSystem` based on `isDarwin`
2. Loads `nix-core.nix` (Nix settings), `hosts/<hostName>/` (host config), rust overlay
3. Wires up home-manager with `./home` as user config
4. Conditionally adds `nixos-wsl` module if `isWSL`

### `specialArgs` — global variables

mkSystem passes these via `specialArgs` to ALL modules including home-manager. Any `.nix` file can use them:

```
hostName, username, myvars, myutils, homeDir,
isDarwin, isWSL, isHeLinux (= !isDarwin && !isWSL), isHmSingle, profileLevel
```

This enables per-platform conditionals everywhere without repeating detection logic.

### Profile Level System

Controls which packages and programs are installed via home-manager. Defined in `lib/vars.nix` as defaults, overridden per-host in `flake.nix`:

```
profileLevel = {
  tuiAdvanced = true;   # larger/complex terminal programs (LSPs, Docker, build tools)
  tuiOptional = false;  # rust toolchain variant: true = rust-bin (full), false = rustc+cargo (minimal)
  guiBase = false;      # basic GUI apps (alacritty, mpv)
  guiHeavy = false;     # heavy GUI applications (placeholder)
};
```

Per-host overrides:
- **expnix**: tuiAdvanced + tuiOptional (full dev, no GUI)
- **nixwsl**: tuiAdvanced only (CUDA dev, minimal)
- **handyMini**: tuiAdvanced + tuiOptional + guiBase (full macOS desktop)

`tui/base` packages have no gate — always included on all hosts.

### `scanPaths` pattern

Import directories that use `scanPaths ./.` (like `nixos/` and `home/tui/`) auto-import all `.nix` files except `default.nix` — drop a new file in and it's automatically included.

## Modules

### `modules/sing-box`

Custom sing-box service module that replaces upstream's `services.networking.sing-box` (disabled in nixos/default.nix). Adds a `configGeneration` sub-option:

- `configGeneration.enable` — pre-start config generation via sbtpl (node.js subscription converter)
- `configGeneration.sourceUrl` — subscription source URL for base.js
- `configGeneration.policyFilter` — policy filter expression
- `configGeneration.extraArgs` — extra arguments to base.js (e.g. `--icmp`, `--log-file`)

On NixOS, creates a systemd service with `ExecStartPre` that runs sbtpl before sing-box starts. Output goes to `/run/sing-box/config.json`.

### `modules/caddy-webdav`

Caddy-based WebDAV server module with options for port, storage path, and basic auth. On macOS, runs as a launchd user agent.

## Home-manager details

- Imports external modules: `my-dotzsh` and `my-nvimdots` (handy-sun forks)
- Rust toolchain: controlled by `profileLevel.tuiOptional` — true → `rust-bin.stable.latest.default`, false → `rustc + cargo`
- WSL: sets `LD_LIBRARY_PATH` to include `/usr/lib/wsl/lib`
- macOS: adds `/opt/homebrew/bin` and `~/.local/bin` to PATH
- Chinese mirrors for Rust (tuna), pip/uv (tuna), npm
- `nh` enabled but `clean.enable = false` (manual GC control)

## macOS launchd agents (handyMini)

All run as user agents with KeepAlive + RunAtLoad:

| Agent | Binary | Purpose |
|-------|--------|---------|
| singb | sing-box | TUN proxy |
| frpc | frp client | Intranet penetration |
| beszel-agent | beszel | System monitoring |
| nginx | nginx | Web server |
| php-fpm | php-fpm | PHP backend |
| caddy-webdav | caddy | WebDAV server |

## Dev Shell

`nix develop` provides `statix` (Nix lint) and `typos` (spell check). The shellHook launches `fish`.

## Key Design Decisions

- Uses `nh` (Nix Helper) for switching, not raw `nixos-rebuild`/`darwin-rebuild`
- On macOS, `nix.enable = false` because Determinate Nix is used instead
- Home-manager `stateVersion = "25.11"`, NixOS `stateVersion = "26.05"`
- System user = `qi`, locale = `zh_CN.UTF-8`, timezone = `Asia/Shanghai`
- Uses Chinese mirrors for Nix substituters (SJTU), Rust (tuna), pip/uv (tuna), homebrew (USTC)
- `EDITOR=nvim`, `VISUAL=nvim` everywhere; NixOS also sets `SYSTEMD_PAGER=nvim`, `SYSTEMD_EDITOR=nvim`
- `PAGER=less`, `LESS=-RX`
- WSL has `cudaSupport = true` and `wsl.useWindowsDriver = true`
- OrbStack uses LXC container module, systemd-networkd for DHCP, and disables all bootloaders
- `nix.gc` runs automatically (7-day retention); `auto-optimise-store` enabled on Linux, disabled on macOS (due to nix#7273)
