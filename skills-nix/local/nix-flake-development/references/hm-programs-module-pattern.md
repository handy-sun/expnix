# Home Manager programs.* Module Pattern

When converting application configs (Lua, TOML, YAML, etc.) to Home Manager's `programs.<name>` module format. Distinct from NixOS/nix-darwin service modules — these write to `~/.config/` via `xdg.configFile`.

## HM Module Structure (Generic)

Most HM programs modules expose these options:

| Option | Type | Purpose |
|---|---|---|
| `enable` | bool | Activate the module |
| `package` | package | Override the package |
| `settings` | `attrsOf anything` | Declarative config, serialized via `lib.generators.toLua` |
| `extraConfig` | `lines` | Raw source code (Lua, etc.), shallow-merges on top of settings |
| `colorSchemes` | `attrsOf TOML` | (WezTerm-specific) TOML color scheme files |

## Generated File Structure

HM generates the config file by combining `settings` + `extraConfig`. For WezTerm, the generated `wezterm.lua` looks like:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder and wezterm.config_builder() or {}

local hm_config = <lib.generators.toLua {} settings>
for k, v in pairs(hm_config) do
  config[k] = v
end

local _hm_extra = (function()
  <extraConfig>
end)()
if type(_hm_extra) == "table" then
  for k, v in pairs(_hm_extra) do
    config[k] = v
  end
end
return config
```

Key behavior:
- `settings` values are merged first (iterating `pairs`)
- `extraConfig` return table is merged second — **shallow merge** (same-key replaces entirely, no recursive merge)
- `extraConfig` without `settings` is emitted as raw code (no wrapper function)

## What Goes Where

### `settings` — simple declarative values
- Strings: `color_scheme = "Catppuccin Mocha"`
- Numbers: `font_size = 16`, `animation_fps = 60`
- Booleans: `enable_tab_bar = true`
- Simple tables: `window_padding = { left = 5; right = 10; }`

### `extraConfig` — anything needing runtime Lua
- API calls: `wezterm.font(...)`, `wezterm.action.*`
- Callbacks: `wezterm.action_callback(function(w, p) ... end)`
- Global state: `wezterm.GLOBAL.xxx`
- Event handlers: `wezterm.on("format-tab-title", function(...) ... end)`
- Complex logic: platform detection, file I/O, dynamic config overrides

### `mkLuaInline` — bridge for settings needing API calls
When a simple value requires a Lua API call, use `mkLuaInline` in `settings`:

```nix
settings = {
  font = lib.generators.mkLuaInline ''wezterm.font_with_fallback({"JetBrains Mono", "Consolas"})'';
};
```

`mkLuaInline` marks the value as raw Lua — `toLua` emits it verbatim instead of serializing it.

**Decision heuristic**: if more than ~30% of settings need `mkLuaInline`, put everything in `extraConfig` instead. Mixing becomes harder to maintain than one coherent Lua block.

## WezTerm Color Scheme TOML

`colorSchemes.<name>` writes to `~/.config/wezterm/colors/<name>.toml`. The TOML must wrap colors under a `colors` key:

```toml
[colors]
foreground = "#e8ecf4"
background = "#1f1f28"
cursor_bg = "#f5e0dc"
cursor_border = "#f5e0dc"
cursor_fg = "#11111b"
selection_bg = "#585b70"
selection_fg = "#e8ecf4"

[colors.ansi]
# black, red, green, yellow, blue, magenta, cyan, white

[colors.brights]
# same 8 colors, brighter variant

[colors.tab_bar]
background = "rgba(0, 0, 0, 0.4)"

[colors.tab_bar.active_tab]
bg_color = "#585b70"
fg_color = "#e8ecf4"
# ...
```

The `colorSchemes` option type is `attrsOf (tomlFormat.type)`, where `tomlFormat = pkgs.formats.toml {}`. The Nix attrset is serialized directly — the top-level `colors` key is part of the value, not the option key.

## Variable Extraction Pattern

Define customizable values as Nix `let` bindings and interpolate into `extraConfig`:

```nix
{ config, lib, pkgs, ... }:
let
  fontFamily = "Maple Mono NF";
  fontFallback = ["NotoMono NFM" "Droid Sans Mono" "Consolas"];
  fontSize = if pkgs.stdenv.isDarwin then 16 else 12;
in {
  programs.wezterm = {
    enable = true;
    colorSchemes.qimocha = { /* ... */ };
    extraConfig = ''
      config.font = wezterm.font_with_fallback({
        "${builtins.head fontFallback}",
        { family = "${fontFamily}", weight = "Medium" },
        ${lib.concatMapStringsSep ", " (f: ''"${f}"'') (builtins.tail fontFallback)}
      })
      config.font_size = ${toString fontSize}
    '';
  };
}
```

## Pitfalls

- **`extraConfig` shallow merge**: returning `{ window_padding = { left = 10; }; }` from extraConfig replaces the ENTIRE `window_padding` from settings, not just the `left` key. Don't split nested tables across both.
- **`settings` + `extraConfig` without return**: if `extraConfig` doesn't return a table, it's still executed (side effects like `wezterm.on()` work), but no config keys are set from it.
- **Color scheme `colors` wrapper**: forgetting the `[colors]` TOML section wrapper means WezTerm can't find the scheme.
- **`mkLuaInline` escaping**: the string inside `mkLuaInline` is raw Lua. Use Nix `''...''` (two single-quotes) for the outer wrapper, and standard Lua quoting inside.
- **Platform detection**: use `pkgs.stdenv.isDarwin` in Nix `let` for compile-time branching, or `wezterm.target_triple` in Lua for runtime branching. Prefer Nix-side when possible.
- **Tab bar colors**: if both TOML and Lua define tab_bar colors, the Lua config overrides (it's merged after). Keep them in one place.
- **TOML vs Lua value drift**: when maintaining both a `.toml` file and Lua overrides, values can diverge. Source of truth should be one or the other, not both.
