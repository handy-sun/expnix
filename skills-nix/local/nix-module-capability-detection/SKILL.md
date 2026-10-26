---
name: nix-module-capability-detection
description: Write or review cross-platform Nix modules that must work in NixOS, nix-darwin, Home Manager, or mixed module systems. Use when choosing between launchd/systemd, Darwin/Linux behavior, or any platform-specific module branch; prefer detecting available options from the module system over relying on externally passed booleans such as isDarwin.
---

# Nix Module Capability Detection

## Core Rule

Prefer capability detection from `options` when a module branch depends on module-system features, such as `launchd`, `systemd`, `users`, or platform-specific services.

Use externally passed flags only for domain intent that is not visible in the option tree. Do not use `isDarwin`, `isLinux`, or host-name heuristics just to decide whether an option namespace exists.

## Pattern

Accept `options` as a module argument, derive booleans in `let`, then choose the branch with a real Nix `if`:

```nix
{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.services.foo;
  hasLaunchd = builtins.hasAttr "launchd" options;
  hasSystemd = builtins.hasAttr "systemd" options;
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = hasLaunchd || hasSystemd;
            message = "services.foo requires launchd or systemd support";
          }
        ];
      }

      (
        if hasLaunchd then
          {
            launchd.user.agents.foo.serviceConfig = {
              # Darwin service config
            };
          }
        else if hasSystemd then
          {
            systemd.services.foo = {
              # NixOS service config
            };
          }
        else
          { }
      )
    ]
  );
}
```

## Why This Matters

Nix module evaluation still validates option paths inside `mkIf false`. This can fail when a false branch contains a top-level option that the current module system does not define.

Avoid this shape in cross-platform modules:

```nix
lib.mkIf isDarwin {
  launchd.user.agents.foo.serviceConfig = { };
}
```

It may still expose `launchd` to NixOS option checking. Use a plain `if` expression, `lib.optionals`, or `lib.optionalAttrs` so the unsupported branch is not present in the returned module value.

## Review Checklist

- Check whether platform-specific branches are based on actual option availability.
- Verify unsupported option namespaces are not present in the final module value.
- Keep shared assertions, packages, generated files, and common options outside the platform branch.
- Add an assertion when the module requires at least one backend.
- Validate by enabling the module in each intended module system, not only by evaluating the default host.

## Validation Commands

For NixOS:

```bash
nix eval --impure --raw --expr 'let flake = builtins.getFlake "path:/path/to/repo"; cfg = flake.nixosConfigurations.host.extendModules { modules = [ /path/to/module { services.foo.enable = true; } ]; }; in cfg.config.systemd.services.foo.serviceConfig.ExecStart'
```

For nix-darwin:

```bash
nix eval --impure --json --expr 'let flake = builtins.getFlake "path:/path/to/repo"; cfg = flake.darwinConfigurations.host.extendModules { modules = [{ services.foo.enable = true; }]; }; in cfg.config.launchd.user.agents.foo.serviceConfig.ProgramArguments'
```
