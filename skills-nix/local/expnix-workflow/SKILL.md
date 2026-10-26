---
name: expnix-workflow
description: Works in the expnix Nix flake repository. Use when editing flake.nix, lib/, home/, hosts/, machines/, modules/, nixos/, overlays/ or packages/, when adding or changing a host, when running builds, evaluations or switches, or when validating formatting and CI checks for this repository.
---

# expnix workflow

Personal Nix flake for NixOS, nix-darwin, system-manager and standalone Home
Manager. `expnix` is the only deployment entry point.

## Layout

| Path | Role |
| --- | --- |
| `flake.nix` | inputs, `nixosConfigurations`, `darwinConfigurations`, `homeConfigurations`, `systemConfigs`, devShells, formatter |
| `lib/` | `mkSystem`, `mkHome`, `mkSysMgr`, shared vars (`vars.nix`), utils |
| `hosts/<name>/` | per-host system configuration |
| `machines/` | platform bases: `nix-core`, `wsl-base`, `orb-base`, `darwin-base` |
| `home/` | Home Manager configuration, split into `tui/` and `gui/` |
| `modules/` | custom NixOS / nix-darwin / system-manager modules |
| `nixos/`, `overlays/`, `packages/` | system defaults, overlays, custom packages |
| `skills-nix/` | agent skill catalog, its own flake and locks |

## Commands

| Task | Command |
| --- | --- |
| enter dev shell | `./scripts/devshell-default.sh` (or `nix develop`) |
| switch system | `just s [host]` (`nh os switch` / `nh darwin switch`); `just sysmgr` for `debnsm` |
| evaluate host toplevel | `just evtop [host]`, `just ev-sysmgr [host]` |
| format | `nix fmt -- <files>`, or `just nixfmt` for the whole tree |
| install git hook | `just setup-hook` |

## Validate before committing

```bash
nix flake check --no-build
nix eval .#homeConfigurations.qi.activationPackage.drvPath --raw
nix build .#homeConfigurations.qi.activationPackage --dry-run
```

CI (`.github/workflows/ci.yml`) runs `nix flake check`, `statix check .` and
`nix build --dry-run` for each NixOS, darwin and Home Manager output. Markdown,
`Justfile`, `.gitignore` and license changes do not trigger it.

## Adding a host

1. Create `hosts/<name>/default.nix`; bare metal also needs
   `hardware-configuration.nix`.
2. Register it in `flake.nix` under `nixosConfigurations` or
   `darwinConfigurations` with `system` and, if needed,
   `profileLevelOver`.
3. Add it to the CI matrix in `.github/workflows/ci.yml`.

## Conventions

- Profile levels come from `lib/vars.nix` (`tuiBase` is always on;
  `tuiAdvanced`, `tuiOptional`, `guiBase`, `guiHeavy` are switches). Hosts
  override them through `profileLevelOver`.
- Modules receive `inputs`, `myvars`, `myutils`, `profileLevel`, `homeDir`,
  `isDarwin`, `isLinux`, `isWSL`, `isHeLinux` and `isHmSingle` through
  `specialArgs` / `extraSpecialArgs`.
- Keep a host's services in `hosts/<host>/services.nix`; leave
  `default.nix` for wiring.
- Secrets use sops-nix with age. Ciphertext lives in `secrets/` and
  `secrets/hosts/<host>/`, recipients in `.sops.yaml`. Never commit
  plaintext, and do not add recipients that a host cannot rotate.
- Every staged `.nix` file must pass `nixfmt --check`; the pre-commit hook
  enforces it.
