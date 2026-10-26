# Noctalia Shell + Niri Integration

Noctalia Shell is a Wayland desktop shell built on Quickshell (Qt/QML) via the `noctalia-qs` fork.
It provides its own launcher, control center, settings panel, notifications, and bar widgets.

## Architecture

```
NixOS module (modules/niri/default.nix)
  ├─ spawns noctalia-shell at startup (via extra.kdl)
  ├─ installs noctalia package (from flake input)
  └─ configures niri window rules + debug flags

Noctalia stores user config in ~/.config/noctalia/ (JSON/QML persistent state)
```

## Key Point: Niri Keybinds vs Noctalia IPC

Niri's default config binds `Mod+D` to `spawn "fuzzel"` (external launcher).
Noctalia has its OWN built-in launcher that must be triggered via IPC.

**Problem**: pressing `Mod+D` opens fuzzel, not noctalia's launcher.

**Fix**: override the keybind in `extra.kdl` to call noctalia's IPC:

```kdl
// In modules/niri/extra.kdl — add binds block
binds {
    Mod+D { spawn "qs" "-c" "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
}
```

Or with `spawn-sh`:
```kdl
binds {
    Mod+D { spawn-sh "qs -c noctalia-shell ipc call launcher toggle"; }
}
```

## Noctalia IPC Commands

Noctalia IPC must be invoked through `qs` (Quickshell runtime), NOT directly through the `noctalia-shell` binary. All commands follow this format:

```
qs -c noctalia-shell ipc call <component> <action>
```

| Function        | IPC Command                    | Description                        |
|-----------------|--------------------------------|------------------------------------|
| Launcher        | `ipc call launcher toggle`     | Open/close application launcher    |
| Control Center  | `ipc call controlCenter toggle`| Toggle control center visibility   |
| Settings        | `ipc call settings toggle`     | Open/close settings panel          |
| Overview        | `ipc call overview toggle`     | Toggle workspace overview          |
| Notifications   | `ipc call notifications toggle`| Toggle notification center         |
| Power Menu      | `ipc call powerMenu toggle`    | Toggle power/session menu          |
| Lock Screen     | `ipc call lockScreen show`     | Show lock screen                   |

Full invocation: `qs -c noctalia-shell ipc call <component> <action>`

## Niri Config Requirements (from noctalia docs)

Add to `extra.kdl` for proper noctalia integration:

```kdl
window-rule {
  // Rounded corners for a modern look
  geometry-corner-radius 20
  // Clips window contents to the rounded corner boundaries
  clip-to-geometry true
}

debug {
  // Allows notification actions and window activation from Noctalia
  honor-xdg-activation-with-invalid-serial
}
```

## Resetting Noctalia Settings

Noctalia stores user settings in `~/.config/noctalia/`. To reset to defaults:

```bash
pkill -f noctalia
rm -rf ~/.config/noctalia/
noctalia &   # recreates with defaults + setup wizard
```

## Package Setup

Noctalia is installed as a system package with a `wrapGAppsHook3` override for GTK theme integration:

```nix
# In modules/niri/default.nix
noctalia =
  let
    pkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in
  pkg.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.wrapGAppsHook3 ];
    dontWrapGApps = true;  # avoid double-wrapping
    preFixup = (oldAttrs.preFixup or []) + ''
      qtWrapperArgs+=("${gappsWrapperArgs[@]}")
    '';
  });
```

Also installs `auto-dark` script for gsettings color-scheme toggling via noctalia's **Theme changed** hook.

## Font and Icon Theme Requirements

Noctalia is a Qt/QML app that reads system font and icon settings via `gsettings` (GNOME desktop interface keys). The `auto-dark` script sets:

```bash
gsettings set org.gnome.desktop.interface icon-theme "breeze-dark"  # or "breeze"
```

**This means `breeze-icons` must be installed**, or Noctalia falls back to Unicode/emoji symbols for all app icons.

For fonts, Noctalia uses the system sans-serif font (via Qt's platform theme). NixOS has NO default font configuration — unlike macOS where `darwin-base.nix` provides fonts. Without explicit font packages, Noctalia renders with a monospace fallback.

**Required additions** in the niri module or host config:

```nix
environment.systemPackages = with pkgs; [
  noctalia
  auto-dark
  gnome-themes-extra  # Adwaita GTK theme
  glib                # gsettings
  kdePackages.breeze-icons  # ← REQUIRED for icons (NOT top-level pkgs.breeze-icons!)
];
```

For fonts, centralize in `lib/vars.nix` so both NixOS and darwin share the same list (see "Shared Configuration via myvars" in the main skill):

```nix
# lib/vars.nix
fonts = {
  packages = with pkgs; [
    noto-fonts              # UI sans-serif
    noto-fonts-cjk-sans     # CJK support
    font-awesome            # icon font
    nerd-fonts.symbols-only # Nerd Font symbols
  ];
};
```

Then reference from both `machines/nix-core.nix` and `machines/darwin-base.nix`:
```nix
fonts = myvars.fonts pkgs;  # Note: myvars.fonts is a function taking pkgs
```

### Diagnosis

When noctalia shows:
- **Unicode/emoji fallback icons** (⚙️📁🖥️) → missing icon theme package (`breeze-icons` if using auto-dark, or whatever gsettings `icon-theme` is set to)
- **Monospace/terminal-like font** → no UI font packages installed on NixOS, add `fonts.packages`

## Pitfalls

- **Noctalia docs site is a SPA** — headless browsers and curl can't render the content; all URLs redirect to `/v4/` overview. Use the **search dialog** on the docs site to find content, or use Jina (`r.jina.ai/docs.noctalia.dev/v4/...`).
- **IPC requires `qs` runtime** — `noctalia-shell` alone doesn't handle IPC. Always prefix with `qs -c noctalia-shell` and use `ipc call <target> <action>`.
- **Icon theme package path** — `auto-dark` sets gsettings to `breeze`/`breeze-dark`, but gsettings alone doesn't install the theme. The correct nixpkgs path is `kdePackages.breeze-icons` (NOT top-level `pkgs.breeze-icons` — that doesn't exist). Without it, noctalia falls back to Unicode symbols.
- **NixOS has no default fonts** — unlike macOS (darwin-base.nix includes nerd-fonts, font-awesome), NixOS systems need explicit `fonts.packages`. Without them, Qt apps use monospace fallback.
- **`guiBase = false` doesn't block system-level fonts** — font and icon packages are in the NixOS module (systemPackages/fonts.packages), not gated by home-manager profileLevel. Even hosts with `guiBase = false` need fonts if they run noctalia.
- **Don't duplicate font lists** — define fonts once in `lib/vars.nix` as `myvars.fonts`, reference from both `nix-core.nix` and `darwin-base.nix`. Keeps NixOS and macOS in sync.

## Chinese/CJK Input

For Chinese input on niri/noctalia, see [references/fcitx5-wayland-input.md](references/fcitx5-wayland-input.md). Uses `i18n.inputMethod` NixOS module with `waylandFrontend = true`.
