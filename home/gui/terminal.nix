{
  lib,
  pkgs,
  inputs,
  profileLevel,
  myvars,
  ...
}:
let
  wezConfDir = inputs.my-wezterm;
  qimocha = (builtins.fromTOML (builtins.readFile (wezConfDir + "/colors/qimocha.toml"))).colors;
in
lib.mkIf profileLevel.guiBase {
  ## ------ wezterm ------
  xdg.configFile = {
    "wezterm/config".source = wezConfDir + "/config";
    "wezterm/events".source = wezConfDir + "/events";
    "wezterm/utils".source = wezConfDir + "/utils";
    "wezterm/backdrops".source = wezConfDir + "/backdrops";
  };

  programs.wezterm = {
    enable = true;

    colorSchemes = { inherit qimocha; };

    settings = {
      color_scheme = "qimocha";

      font_size = if pkgs.stdenv.isDarwin then 16.0 else 12.0;
      font = lib.generators.mkLuaInline ''
        wezterm.font_with_fallback({
          "${myvars.fontFamily}",
          "FiraCode Nerd Font Mono",
          "JetBrains Mono",
          "DejaVu Sans Mono",
          "Droid Sans Mono",
          "Consolas",
        })
      '';

      freetype_load_target = "Normal";
      freetype_render_target = "Normal";
    };

    extraConfig = builtins.readFile (wezConfDir + "/extra.lua");
  };

  ## ------ alacritty ------
  programs.alacritty = {
    enable = true;
    settings = {
      colors = {
        primary = {
          background = "#343d46";
          foreground = "#D8DEE9";
        };
        normal = {
          black = "#1E1E1E";
          red = "#EC5F66";
          green = "#99C794";
          yellow = "#F9AE58";
          blue = "#6699CC";
          magenta = "#C695C6";
          cyan = "#5FB4B4";
          white = "#F7F7F7";
        };
        bright = {
          black = "#B4B4A6";
          red = "#F97B58";
          green = "#ACD1A8";
          yellow = "#FAC761";
          blue = "#85ADD6";
          magenta = "#D8B6D8";
          cyan = "#82C4C4";
          white = "#FAFAFA";
        };
      };
      bell = {
        animation = "EaseOutExpo";
        color = "0xFF0000";
        duration = 0;
      };
      cursor = {
        vi_mode_style = "None";
      };
      font = {
        size = 16;
        bold = {
          family = myvars.fontFamily;
        };
        italic = {
          family = myvars.fontFamily;
        };
        normal = {
          family = myvars.fontFamily;
          style = "Regular";
        };
      };
      scrolling = {
        history = 15000;
        multiplier = 5;
      };
      window = {
        decorations = "None";
        dynamic_padding = true;
        dynamic_title = true;
        opacity = 0.98;
        startup_mode = "Maximized";
        dimensions = {
          columns = 0;
          lines = 0;
        };
        padding = {
          x = 0;
          y = 0;
        };
      };
      general = {
        live_config_reload = true;
      };
      selection = {
        semantic_escape_chars = ",│`|:\"'()[]{}<>";
        save_to_clipboard = true;
      };
      keyboard = {
        bindings = [
          {
            action = "SpawnNewInstance";
            key = "Return";
            mods = "Control|Shift";
          }
        ];
      };
    };
  };
}
