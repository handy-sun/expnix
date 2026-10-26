# Fcitx5 Chinese Input on Wayland (Niri/Noctalia)

Setting up Chinese (CJK) input on Wayland compositors like niri requires fcitx5 with Wayland frontend support.

## NixOS Configuration

Use the built-in `i18n.inputMethod` module, gated by `profileLevel.guiBase`:

```nix
# nixos/default.nix
{
  pkgs, lib, profileLevel, ...
}:
{
  i18n = {
    inputMethod = lib.mkIf profileLevel.guiBase {
      enable = true;
      type = "fcitx5";
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons  ## pinyin input (renamed from fcitx5-chinese-addons)
        fcitx5-gtk                         ## GTK application support
      ];
    };
  };
}
```

This automatically:
- Installs fcitx5 and addons
- Sets environment variables (`INPUT_METHOD`, `GTK_IM_MODULE`, `QT_IM_MODULE`, `XMODIFIERS`)
- Configures fcitx5 as a systemd user service

## Usage

1. Apply config: `just switch`
2. Fcitx5 auto-starts on login
3. `Ctrl+Space` toggles Chinese/English input
4. `fcitx5-configtool` for configuration (add/remove input methods, set hotkeys)

## Required Packages

| Package | Purpose |
|---------|---------|
| `fcitx5` | Input method framework |
| `qt6Packages.fcitx5-chinese-addons` | Pinyin, table-based Chinese input (renamed from `fcitx5-chinese-addons`) |
| `fcitx5-gtk` | GTK application integration |
| `fcitx5-qt` | Qt application integration (often auto-pulled) |
| `fcitx5-rime` | RIME engine (alternative to pinyin, more configurable) |

## Wayland-Specific Notes

- `fcitx5.waylandFrontend = true` uses the Wayland input method protocol (not XIM)
- This is required for proper integration with Wayland compositors
- Without it, fcitx5 falls back to XIM which may not work in Wayland-native apps
- GTK_IM_MODULE and QT_IM_MODULE env vars are set automatically by the NixOS module

## Pitfalls

- **`profileLevel.guiBase` gating**: fcitx5 is a system service, not a user package. Gate it in the NixOS module (`nixos/default.nix`), not in home-manager `packages/base.nix`.
- **Missing `waylandFrontend`**: without this, input may not work in Wayland-native apps (only in XWayland apps).
- **Noctalia/Qt apps**: fcitx5-qt is needed for Qt apps. It's usually auto-pulled but verify if noctalia doesn't respond to input method.
- **Rime vs Pinyin**: `fcitx5-chinese-addons` provides simple pinyin. For more advanced Chinese input (Wubi, custom dictionaries), use `fcitx5-rime` instead.
- **Environment variables**: the NixOS `i18n.inputMethod` module sets these automatically. Don't set them manually in environment.variables — they conflict.
- **Package rename**: `fcitx5-chinese-addons` has been renamed to `qt6Packages.fcitx5-chinese-addons` in nixpkgs. Using the old name causes: `error: 'fcitx5-chinese-addons' has been renamed to/replaced by 'qt6Packages.fcitx5-chinese-addons'`.
