---
name: nix-flake-development
description: >-
  Patterns for developing NixOS/nix-darwin flakes: adding services with overlays,
  fixing platform-specific package builds, and plumbing specialArgs through
  mkSystem/mkHome. Use when adding daemons, creating local package overrides,
  or wiring new parameters through the flake module system.
---

# Nix Flake Development Patterns

Reusable patterns for working with NixOS/nix-darwin flakes. Covers four common workflows: adding system services, fixing broken packages, plumbing configuration parameters, and adding new hosts.

## When to Use

- Adding a new long-running service (daemon, agent, server) to a flake
- A nixpkgs package fails on one platform and you need a local fix
- Adding a new parameter that needs to flow from flake.nix into modules
- Converting traditional config files (nginx.conf, etc.) to declarative Nix modules — see [references/converting-configs-to-nix.md](references/converting-configs-to-nix.md)
- Converting app configs (Lua/TOML/YAML) to Home Manager `programs.*` modules (settings/extraConfig/mkLuaInline) — see [references/hm-programs-module-pattern.md](references/hm-programs-module-pattern.md)
- Splitting config between NixOS `/etc/` and home-manager `~/.config/` (include-chain pattern for niri, sway, etc.) — see [references/split-level-config.md](references/split-level-config.md)
- Setting up CI for a multi-system Nix flake (GitHub Actions or Garnix) — see [references/github-actions-ci.md](references/github-actions-ci.md)
- Setting up Chinese/Japanese/Korean input on Wayland (fcitx5 with niri/noctalia) — see [references/fcitx5-wayland-input.md](references/fcitx5-wayland-input.md)
- Adding a new machine/host to the flake (bare-metal NixOS, WSL, OrbStack, or macOS)
- Installing NixOS from scratch on bare metal with btrfs — see [references/nixos-bare-metal-install-btrfs.md](references/nixos-bare-metal-install-btrfs.md)

---

## Pattern 1: Adding a System Service

When adding a new service to the expnix flake, create a reusable module under `modules/` plus any necessary overlay for custom package builds.

### Anatomy

```
modules/<name>/default.nix   →  options (enable, package, config) + config (packages, activation, service)
                                 Can also embed the overlay directly (see self-contained module below).
overlays/<name>.nix          →  custom package build (if nixpkgs package needs plugins)
                                 OPTIONAL — prefer embedding in the module for self-containment.
hosts/<host>/default.nix     →  import module + services.<name>.enable = true
```

### Self-contained module (overlay embedded)

When the overlay is small and only serves this one service, embed it directly in the module. Place `nixpkgs.overlays` at the **top level** (NOT inside `lib.mkIf cfg.enable`), because `lib.mkPackageOption` evaluates the package reference at option-declaration time:

```nix
# modules/<name>/default.nix
{
  # UNCONDITIONAL — must exist before options reference the package name
  nixpkgs.overlays = [
    (final: prev: {
      <name>-custom = prev.<pkg>.withPlugins { ... };
    })
  ];

  options.services.<name> = {
    package = lib.mkPackageOption pkgs "<name>-custom" { };  # now resolves
    # ...
  };
  # ...
}
```

### Step-by-step

1. **Determine if you need an overlay** — check if the nixpkgs package has all required features (e.g., `caddy list-modules`). If missing features require a custom build, create an overlay.

2. **Create the overlay** (if needed) — for packages with `withPlugins` (caddy, etc.):

```nix
# overlays/<name>.nix
{ lib, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      <name>-custom = prev.caddy.withPlugins {
        plugins = [
          "github.com/<owner>/<repo>@v0.0.0-<YYYYMMDDHHMMSS>-<commit_12char>"
        ];
        # hash defaults to lib.fakeHash — replace after first build prints expected value
      };
    })
  ];
}
```

**Go pseudo-version format**: `v0.0.0-YYYYMMDDHHMMSS-<12-char-commit-hash>`. Get latest commit from `https://api.github.com/repos/<owner>/<repo>/commits/master`.

**Hash workflow**: omit `hash` (defaults to `lib.fakeHash`). First `just switch` fails with hash mismatch — nix prints the expected value. Copy it and set `hash = "sha256-..."`. Rebuild.

3. **Create the module**:

```nix
# modules/<name>/default.nix
{
  config, lib, pkgs, username, homeDir, isDarwin, ...
}:
let
  cfg = config.services.<name>;
in
{
  options.services.<name> = {
    enable = lib.mkEnableOption "<description>";
    package = lib.mkPackageOption pkgs "<name>-custom" { };
    # Service-specific options here
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      { environment.systemPackages = [ cfg.package ]; }
      {
        system.activationScripts.<name>.text = ''
          mkdir -p <path>
          chown ${username}:staff <path>    # macOS group
        '';
      }
      (lib.mkIf isDarwin {
        launchd.user.agents.<name>.serviceConfig = {
          Label = "nixdwn.${username}.<name>";
          UserName = username;
          ProgramArguments = [
            "${lib.getExe cfg.package}"
            # ... args
          ];
          WorkingDirectory = cfg.storagePath;
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "/tmp/<name>.log";
          StandardErrorPath = "/tmp/<name>.log";
        };
      })
      # For NixOS: systemd.services.<name> = { ... };
    ]
  );
}
```

4. **Wire into host config**:

```nix
# hosts/<host>/default.nix
{
  imports = (
    lib.map myutils.relativeToRoot [
      "machines/darwin-base.nix"
      "overlays/<name>.nix"      # ← add overlay
      "modules/<name>"           # ← add module
    ]
  );
  services.<name>.enable = true;
}
```

Order matters: overlay before module so the package exists when the module references it.

5. **Test**: `just switch` on the target host. Verify with `launchctl list | grep nixdwn.qi.<name>`. Logs at `/tmp/<name>.log`.

### Service Module Pitfalls

- **Missing feature in nixpkgs package**: always verify with the actual binary first (`list-modules`, `--version`, etc.)
- **Go plugin hash workflow**: first build is slow (5-15 min) for Go dependency download
- **Activation script chown on macOS**: use `username:staff`, not `username:root`
- **Module args**: `username`, `homeDir`, `isDarwin` are in specialArgs — use them, not `myvars.user`
- **Overlay as module**: overlays in this flake are imported as MODULES (via host imports), not directly as `nixpkgs.overlays`
- **Embedded overlay must be unconditional**: outside `lib.mkIf cfg.enable` or `lib.mkPackageOption` fails
- **XDG_DATA_HOME**: some tools (caddy) need this in the launchd environment
- **Config format adapters**: for text configs (Caddyfile), add adapter flag to ProgramArguments
- **Non-ordered handler directives**: some servers (Caddy) need `route { }` blocks for non-ordered handlers
- **Generic modules over hardcoded**: when user says "写通用的内容", extract all host-specific values into options. Use `attrsOf submodule` for collections (multiple proxy sites, users, etc.). The module defines structure; the host provides values.
- **User-level launchd**: prefer `launchd.user.agents` over system-level services to avoid root. Label pattern: `"nixdwn.${username}.<name>"`

---

## Pattern 2: Local Package Overlay (Platform Fix)

When a nixpkgs package fails on only one platform and an upstream fix exists but isn't in the locked revision, create a local overlay. Lighter than updating nixpkgs.

### When to use

- Build failure is platform-specific (only on `stdenv.isDarwin`, `isx86_64`, etc.)
- An upstream nixpkgs issue/PR exists with a known fix
- The locked nixpkgs revision doesn't include the fix
- You don't want to bump nixpkgs (too many other changes)

### Anatomy

```
flake.nix                    →  no changes needed
hosts/<host>/default.nix     →  add "overlays/<name>.nix" to imports
overlays/<name>.nix          →  overrideAttrs to skip checkPhase or apply patch
```

### Step-by-step

1. **Identify the issue**. Search nixpkgs issues for the package + platform. Confirm the upstream fix.

2. **Create `overlays/<pkg>.nix`**:

```nix
# overlays/direnv.nix
# Fixed in nixpkgs#513971 (zsh sigsuspend probe).
# Remove this overlay after flake lock catches up.
{ nixpkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      direnv = prev.direnv.overrideAttrs (old: {
        doCheck = if prev.stdenv.isDarwin then false else old.doCheck;
      });
    })
  ];
}
```

Key conventions:
- Use `prev.stdenv.isDarwin` to scope the fix
- Prefer disabling `doCheck` when the check itself is the problem
- Add a comment with the upstream issue/PR reference
- Add a note to remove the overlay when nixpkgs catches up

3. **Import in the affected host** — only import on the host that actually needs it.

4. **Test**: `just switch` on the affected host.

5. **Cleanup**: when `just upc-nix` brings in a nixpkgs revision that includes the upstream fix, delete the overlay file and remove its import.

### Local Overlay Pitfalls

- **Wrong guard**: `stdenv.isDarwin` in an overlay uses `prev.stdenv`, not the calling host's stdenv
- **Overlay vs module import**: `overlays/*.nix` files are imported as MODULES, not directly as `nixpkgs.overlays`
- **Too broad override**: `doCheck = false` on ALL platforms is heavy-handed — scope to the affected platform
- **Forgetting cleanup**: comment should state when the overlay can be removed

---

## Pattern 3: specialArgs Plumbing

When adding a new parameter that needs to reach home-manager (or NixOS) modules, the following files must be touched. Missing any step causes "undefined variable" errors at eval time.

### Anatomy

```
vars.nix         →  define default value
mksystem.nix     →  accept param (default from myvars), add to specialArgs
mkhome.nix       →  accept param (default from myvars), add to extraSpecialArgs
flake.nix        →  optionally override per-host in mkSystem { ... }
home/default.nix →  receive param in function args, consume it
home/tui/*.nix   →  receive param in function args if used (scanPaths modules)
```

### Step-by-step

1. **Define default** in `lib/vars.nix` — place it in the `rec { ... }` attrset.

2. **mkSystem**: add param with `? myvars.paramName` default, then add to `specialArgs` (the `inherit (...) ... ;` block). This makes it available to all NixOS/darwin modules AND home-manager via `extraSpecialArgs = specialArgs`.

3. **mkHome**: same pattern. Add param, add to `extraSpecialArgs` inherit block.

4. **flake.nix**: each `mkSystem "hostname" { ... }` call can override the default.

5. **home/default.nix**: add param to the `{ pkgs, lib, ... }:` destructure. Use `profileLevel.xxx` or `lib.optionals profileLevel.xxx [...]`.

6. **home/tui/*.nix** (and any scanPaths-imported module): if the module references the new param, it MUST be added to that module's function args. The `...` catch-all does NOT include specialArgs — you must name it explicitly.

### Multi-State Options: nullOr enum Pattern

When a boolean `mkEnableOption` evolves into 3+ behaviors, refactor to a `nullOr (enum [...])` option. This gives the caller explicit control and avoids the ambiguous "false means default or off?" problem.

**Before** (boolean — ambiguous):
```nix
enableGreeting = mkEnableOption "set custom greeting";
# false → does it mean "use fish default" or "suppress greeting"?
```

**After** (tri-state — explicit):
```nix
greetingMode = lib.mkOption {
  type = lib.types.nullOr (lib.types.enum [ "empty" "custom" ]);
  default = null;
  description = "null = fish default, empty = suppress, custom = project greeting";
};
```

**Consumer pattern** — dispatch on the enum value:
```nix
# In activation scripts (string concatenation):
extraArgs = (if cfg.greetingMode == "custom" then "g" else "");

# In shellInitLast / initContent (conditional injection):
${lib.optionalString (cfg.greetingMode == "empty") "set fish_greeting"}
```

**Naming convention**: use `*Mode` suffix for the option name (e.g. `fishGreetingMode`, `colorMode`, `updateMode`). The enum values should be lowercase descriptive strings, not numbers.

**When to use**: any option where "off" has two meanings (skip entirely vs explicitly disable), or where there are 3+ distinct behaviors. Common cases: logging level, color scheme selection, update strategy, greeting/notification behavior.

### Shared Configuration via myvars

When configuration should be identical across NixOS and darwin (fonts, environment variables, etc.), define it once in `lib/vars.nix` and reference it from both `machines/nix-core.nix` and `machines/darwin-base.nix`.

**When the shared config needs `pkgs`** (e.g., font packages), `vars.nix` must remain a plain set (not a function) because `flake.nix` does `import ./lib/vars.nix` expecting a set. Make the attribute itself a function that takes `pkgs`:

```nix
# lib/vars.nix — keep as set, make fonts a function
rec {
  user = "qi";
  ## ... other vars ...

  ## Fonts shared across NixOS and darwin.
  ## Takes pkgs as argument, returns font set.
  fonts = pkgs: {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      font-awesome
      nerd-fonts.symbols-only
    ];
  };
}
```

```nix
# machines/nix-core.nix — call with pkgs
{ pkgs, myvars, ... }: {
  fonts = myvars.fonts pkgs;
}
```

```nix
# machines/darwin-base.nix — call with pkgs
{ pkgs, myvars, ... }: {
  fonts = myvars.fonts pkgs;
}
```

**When the shared config is pure data** (no `pkgs` reference), keep it as a plain attribute:

```nix
# lib/vars.nix
rec {
  commonEnv = { LANG = "zh_CN.UTF-8"; PAGER = "less"; };
}
```

```nix
# Both machines reference directly
{ myvars, ... }: {
  environment.variables = myvars.commonEnv;
}
```

This avoids duplication and ensures both platforms stay in sync.

### Nix Comment Convention

- All comments in English (never Chinese/Japanese/etc.)
- `#` for comments that might be uncommented later (disabled options, alternative configs)
- `##` for explanatory comments that will never be uncommented (descriptions, rationale, notes)
- Inline comments after code follow the same rule: `nerd-fonts.symbols-only ## symbols icon only`

### specialArgs Pitfalls

- **specialArgs are NOT module options**: `specialArgs` values (like `profileLevel`, `username`, `isDarwin`) are injected as **function arguments** to modules, not as `config.*` attributes. In `nix repl` or `nix eval`, you CANNOT access them via `config.profileLevel` or `config.home-manager.users.qi.profileLevel`. If you evaluate `myvars.profileLevel` in the repl, you get the **default** from `vars.nix`, NOT the per-host override from `flake.nix`. The per-host override only exists during actual module evaluation (passed as a function arg). To verify a per-host value, evaluate the **consumer** instead: `nix eval .#nixosConfigurations.buking.config.home-manager.users.qi.programs.yazi.enable` — if this returns the expected value, the override is working.
- **vars.nix must be a set, not a function**: `flake.nix` does `import ./lib/vars.nix` expecting a set. If `vars.nix` is `{ pkgs }: rec { ... }`, this fails with `error: expected a set but found a function`. When you need `pkgs` in a shared config (e.g., font packages), make the **attribute** a function: `fonts = pkgs: { packages = with pkgs; [...]; };` and call it in consumers: `fonts = myvars.fonts pkgs;`.
- **Forgetting sub-module args**: `scanPaths` auto-imports sub-modules. If you use a specialArg without adding it to function parameters, Nix eval fails with "undefined variable".
- **Stale unused params**: remove unused params from function signatures after refactoring.
- **String escaping**: `\\$` in a double-quoted string produces `\$`. For shell `${VAR}`, use `\\${VAR}` in Nix strings.
- **isHmSingle**: mkSystem sets `false`, mkHome sets `true`. Use for conditional logic.
- **Platform conditionals**: `isLinux`/`isDarwin`/`isWSL`/`isHeLinux` available everywhere. Don't duplicate packages across level AND platform groups — pick one dimension.

### Split-file pattern with packages/ subdirectory

Home-manager config uses a two-level `scanPaths` nesting. All `home.packages` definitions live under `packages/` subdirectories, separated by level:

```
home/
├── default.nix           # session vars, paths, imports (no packages)
├── tui/
│   ├── default.nix       # imports = myutils.scanPaths ./.;  (no packages)
│   ├── packages/
│   │   ├── default.nix   # imports = myutils.scanPaths ./.;
│   │   ├── base.nix      # tuibase — always included, unconditional
│   │   ├── advanced.nix  # lib.optionals profileLevel.tuiAdvanced [...]
│   │   ├── optional.nix  # if profileLevel.tuiOptional then [heavy] else [light]
│   │   └── platform.nix  # lib.optionals isLinux [...] ++ lib.optionals isDarwin [...]
│   └── ...               # shells, ssh, xdg, misc (unconditional config, no packages)
└── gui/
    ├── default.nix       # imports = myutils.scanPaths ./.;  (mirrors tui/)
    └── packages/
        ├── default.nix
        ├── base.nix      # lib.mkIf profileLevel.guiBase { home.packages = [...]; }
        └── heavy.nix     # lib.mkIf profileLevel.guiHeavy { ... }
```

Key rules:
- tuibase never has a boolean — lives in `base.nix` unconditionally
- Each level file uses `lib.optionals profileLevel.xxx [...]`
- Platform conditionals in their own file — never mix with level-gated packages
- GUI modules use `lib.mkIf profileLevel.xxx { ... }` at module level
- `home/tui/default.nix` only needs `{ myutils, ... }:` — just imports via `scanPaths`

## Pattern 4: Adding a New Host

When adding a new machine to the flake, create a host config and register it in `flake.nix`.

### Anatomy

```
hosts/<name>/default.nix   →  imports + host-specific config (GPU, audio, network, services)
flake.nix                  →  nixosConfigurations.<name> = mkSystem "<name>" { ... }
```

### Step-by-step

1. **Create `hosts/<name>/default.nix`**:

```nix
{
  lib,
  pkgs,
  myvars,
  myutils,
  homeDir,
  ...
}:

{
  imports = lib.map myutils.relativeToRoot [
    "nixos"            # shared NixOS modules (system packages, sing-box, services)
    # "machines/orb-base.nix"   # for OrbStack LXC
    # "machines/wsl-base.nix"   # for WSL2
    "modules/niri"     # optional — desktop compositor
  ];

  # CRITICAL for bare-metal hosts: declare user (OrbStack/WSL handle this in their base modules)
  users.users.${myvars.user} = {
    isNormalUser = true;
    home = homeDir;
    createHome = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Desktop/GUI host:
  hardware.graphics.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };
  networking.networkmanager.enable = true;

  # CI stubs — bare-metal hosts need these for nix flake check to pass.
  # Replace with real values on actual deployment.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.grub.device = "/dev/sda";
}
```

Import decision tree for `machines/`:
- OrbStack LXC → `machines/orb-base.nix`
- WSL2 → `machines/wsl-base.nix` + set `isWSL = true` in flake.nix
- macOS → `machines/darwin-base.nix` + set `isDarwin = true` in flake.nix
- Bare-metal Linux → no machine base needed (just `nixos`)

2. **Register in `flake.nix`**:

For NixOS (bare metal or WSL):
```nix
nixosConfigurations = {
  "<name>" = mkSystem "<name>" {
    system = "x86_64-linux";          # or aarch64-linux
    isWSL = true;                     # only for WSL hosts
    profileLevel = {
      tuiAdvanced = true;
      tuiOptional = true;
      guiBase = true;
      guiHeavy = true;
    };
  };
};
```

For macOS:
```nix
darwinConfigurations = {
  "<name>" = mkSystem "<name>" {
    system = "aarch64-darwin";       # or x86_64-darwin
    isDarwin = true;
    profileLevel = { ... };
  };
};
```

profileLevel fields (all default false except tuiAdvanced via `lib/vars.nix`):
- `tuiAdvanced` — larger terminal programs (LSP, Docker, build tools)
- `tuiOptional` — rust toolchain: true = rust-bin (full), false = rustc+cargo (minimal)
- `guiBase` — basic GUI apps (alacritty, mpv)
- `guiHeavy` — heavy GUI applications

### Host Pitfalls

- **Bare-metal NixOS requires user declaration**: OrbStack and WSL hosts get user setup from their respective base modules (`orb-base.nix` with `isSystemUser`, `nixos-wsl` with `defaultUser`). Bare-metal NixOS hosts have NO such module — the user is left as `isNormalUser = false` with `home = "/var/empty"` (NixOS default for non-normal users). This conflicts with home-manager's `home.homeDirectory = "/home/<user>"`. **Fix**: add `users.users.<name> = { isNormalUser = true; home = homeDir; createHome = true; extraGroups = [ "wheel" ]; }` in the host config. Also add `myvars` and `homeDir` to the function args — both come from `specialArgs`.
- **Bare-metal NixOS needs `fileSystems` and `boot.loader` stubs**: CI (`nix flake check`) evaluates the full system including filesystem and bootloader requirements. Container/WSL hosts bypass this via their base modules (LXC container, WSL module). Bare-metal hosts fail with: "The 'fileSystems' option does not specify your root file system" and "You must set the option 'boot.loader.grub.devices'". **Fix**: add dummy stubs in the host config: `fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };` and `boot.loader.grub.device = "/dev/sda";`. These are placeholders for CI — replace with real values on actual deployment.
- **Forgetting `hardware.graphics.enable`**: desktop/GUI hosts need this. Without it, Wayland compositors won't start.
- **Forgetting pipewire**: audio won't work on a desktop without `services.pipewire`.
- **Isolated home-manager**: `isWSL`/`isDarwin` flags affect home-manager behavior (LD_LIBRARY_PATH on WSL, PATH additions on Darwin). Double-check they're set correctly.
- **scanPaths auto-discovery**: `home/gui/` and `home/tui/` use `scanPaths` — any `.nix` file dropped there is auto-imported. The niri home-manager config (`home/gui/niri.nix`) is picked up automatically.
- **CI exposes pre-existing failures**: when adding a new host, `flake-check` fails first. Fixing it may expose the build stage for the first time — other hosts' builds may fail due to pre-existing issues (network flakiness, codeberg.org unreachable, etc.) that were previously masked because CI never reached that stage. Don't chase unrelated build failures.


### Optional-level else-branch (fallback)

When a level is OFF, use `if/then/else` instead of dual `lib.optionals`:

```nix
home.packages = with pkgs;
  (
    if profileLevel.tuiOptional then
      [ rust-bin.stable.latest.default ]   # heavy rust-overlay build
    else
      [ rustc cargo ]                       # lightweight nixpkgs fallback
  );
```

Parentheses required because `with pkgs;` scopes the entire expression.
