# expnix - NixOS / homemanager Configuration

## Bootstrapping on a Fresh System

If you are on a freshly installed NixOS system, you can use the following steps to start configuring and compiling this system configuration.

> **Note**: Ensure you are in the root directory of the repository (where the `Justfile` is located) when running these commands.

1. **Get `just` command runner:**
   First, start a temporary shell with `just` installed to run the tasks defined in our `Justfile`.

   ```bash
   nix shell --extra-experimental-features "flakes nix-command" nixpkgs#just
   ```

2. **Prepare dependencies (`preshell`):**
   Once you have `just`, run the `preshell` target to enter a subshell environment pre-loaded with necessary tools like `nh` (Nix Helper) and `git` which are required for the build.

   ```bash
   just preshell
   ```

3. **Build and Switch:**
   Within the `preshell` environment, you can now start the compilation process to switch and activate the new NixOS configuration.

   ```bash
   just switch
   ```

   *(This command invokes `nh os switch .` under the hood on Linux systems).*

## Useful Commands

You can find more available commands by running:
```bash
just
```

For development, you might also want to set up git hooks:
```bash
just setup-hook
```
