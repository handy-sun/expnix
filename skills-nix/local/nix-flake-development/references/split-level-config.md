# Split-Level Config: NixOS + home-manager Coordination

When a program supports `include` directives (niri `.kdl`, sway `.conf`, etc.), you can split
configuration between system-level (`/etc/`) and user-level (`~/.config/`).

## Architecture

```
system-level (NixOS module)          user-level (home-manager module)
/etc/<prog>/config.kdl               ~/.config/<prog>/config.kdl  ← entry point
  ├─ include "default-config"          ├─ include "/etc/<prog>/config.kdl"
  └─ include "extra.kdl"               └─ include "~/.config/<prog>/extra.kdl"
  (base defaults + system extras)      (user keybinds, spawns, etc.)
```

User's `config.kdl` is the entry point. It chains into system config, then adds user overrides.

## NixOS module (modules/<name>/default.nix)

```nix
{ pkgs, lib, ... }:
let
  baseConfig = pkgs.writeText "<name>-base-config.kdl" ''
    include "${pkgs.<name>.src}/resources/default-config.kdl"
    include "extra.kdl"
  '';
in
{
  programs.<name>.enable = true;

  environment.etc = {
    "<name>/config.kdl".source = baseConfig;
    "<name>/extra.kdl".source = pkgs.replaceVars ./extra.kdl {
      placeholder-pkg = pkgs.some.package;
    };
  };
}
```

## home-manager module (home/gui/<name>.nix)

```nix
{ config, lib, pkgs, ... }:
let
  conf = config.xdg.configHome;
  progConf = conf + "/<name>";
  userConfig = pkgs.writeText "<name>-user-config.kdl" ''
    include "/etc/<name>/config.kdl"
    include "${progConf}/extra.kdl"
  '';
in
{
  home.file = {
    "${progConf}/config.kdl".source = userConfig;
    "${progConf}/extra.kdl".source = ./<name>-extra.kdl;
  };
}
```

## Key techniques

- **`pkgs.replaceVars`** — template `.kdl`/`.conf` files with `@placeholder@` syntax.
  Replaces `@varname@` with the provided derivation. Placeholders must match the attrset keys.
- **`pkgs.writeText`** — generate config files that include Nix store paths.
  Used for both system `baseConfig` and user `userConfig` (the include chains).
- **`home.file` vs `xdg.configFile`** — if the path already includes `config.xdg.configHome`,
  use `home.file`. If it's relative to `$XDG_CONFIG_HOME`, use `xdg.configFile`.

## When to use

- Program supports `include` or `config.d/` directory pattern
- You want base config at system level (declarative, immutable)
- User customizations at `~/.config/` (user-owned, can be overridden without root)

## Pitfalls

- **niri**: `programs.niri.enable` must be on the NixOS side — home-manager alone won't
  install the binary or create the systemd session.
- **Home-manager `home.file` produces symlinks** — the target file in `~/.config/` is a
  symlink to the Nix store. This is fine for config files but NOT for programs that
  overwrite their config in-place.
- **Include paths**: system config uses relative paths (`include "extra.kdl"`),
  user config uses absolute paths (`include "/etc/<name>/config.kdl"`).
- **`replaceVars` keys**: must be valid Nix identifiers (no dots, no dashes — use camelCase
  or snake_case). But the `@placeholder@` in the source file uses the exact string.
