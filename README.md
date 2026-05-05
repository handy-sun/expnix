# expnix - NixOS / homemanager Configuration

## Bootstrapping on a Fresh System

For a freshly installed NixOS or macOS system, follow these steps to build and activate the configuration.

> **Note**: Run all commands from the repository root (where the `Justfile` is located).

1. **Enter the dev shell(Only first time):**

   ```bash
   export NIX_CONFIG='extra-experimental-features = nix-command flakes'
   nix develop
   ```

   This drops you into a shell with `just`, `nh`, and `git` available. The `NIX_CONFIG` line is only needed if your system `nix.conf` does not already enable flakes.

2. **Build and activate:**

   ```bash
   just switch
   ```

   On Linux this runs `nh os switch .`, on macOS it runs `nh darwin switch .`.

3. **To switch home-manager only** (without rebuilding the full system):

   ```bash
   just switch-home
   ```

## Useful Commands

List all available commands:
```bash
just
```

Set up git hooks:
```bash
just setup-hook
```
