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
  font_size = if pkgs.stdenv.isDarwin then 16 else 12;
  fish = lib.getExe pkgs.fish;
  zsh = lib.getExe pkgs.zsh;
  bash = lib.getExe pkgs.bash;
in
lib.mkIf profileLevel.guiBase {
  ## ------ wezterm ------
  xdg.configFile = {
    "wezterm/config".source = wezConfDir + "/config";
    "wezterm/events".source = wezConfDir + "/events";
    "wezterm/utils".source = wezConfDir + "/utils";
    # Force Alacritty to use NerdFontSymbolsOnly for PUA glyphs instead of
    # the embedded Nerd Font outlines in Maple Mono NF CN which Alacritty's
    # renderer renders as transparent.
    "fontconfig/conf.d/10-nerd-font-symbols.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <alias>
          <family>Maple Mono NF CN</family>
          <prefer>
            <family>NerdFontSymbolsOnly</family>
          </prefer>
        </alias>
      </fontconfig>
    '';
  };

  xdg.dataFile = lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
    "applications/kitty.desktop".source = pkgs.runCommand "kitty-desktop-entry" { } ''
      sed 's|^Exec=kitty$|Exec=${lib.getExe pkgs.kitty} --start-as=maximized|' \
        ${pkgs.kitty}/share/applications/kitty.desktop > $out
    '';
  };

  programs.wezterm = {
    enable = true;

    colorSchemes = { inherit qimocha; };

    settings = {
      color_scheme = "qimocha";
      default_prog = [
        fish
        "-il"
      ];
      launch_menu = [
        {
          label = "Fish";
          args = [
            fish
            "-il"
          ];
        }
        {
          label = "Fish (Private)";
          args = [
            fish
            "-il"
            "-P"
          ];
        }
        {
          label = "Zsh";
          args = [
            zsh
            "-il"
          ];
        }
        {
          label = "Bash";
          args = [
            bash
            "-l"
          ];
        }
      ];

      inherit font_size;
      font = lib.generators.mkLuaInline ''
        wezterm.font_with_fallback({
          "${myvars.fontFamily}",
          "NotoMono NFM",
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

  ## ------ kitty ------
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    darwinLaunchOptions = [ "--start-as=maximized" ];

    font = {
      name = myvars.fontFamily;
      size = font_size;
    };

    settings = {
      shell = "${fish} -il";

      background = "#1f1f28";
      foreground = "#d8dfda";
      selection_background = "#585b70";
      selection_foreground = "#d8dfda";
      cursor = "#f5e0dc";
      cursor_text_color = "#11111b";
      color0 = "#1E1E1E";
      color1 = "#EC5F66";
      color2 = "#99C794";
      color3 = "#F9AE58";
      color4 = "#6699CC";
      color5 = "#C695C6";
      color6 = "#5FB4B4";
      color7 = "#F0F1F0";
      color8 = "#B4B4A6";
      color9 = "#F97B58";
      color10 = "#ACD1A8";
      color11 = "#FAC761";
      color12 = "#85ADD6";
      color13 = "#D8B6D8";
      color14 = "#82C4C4";
      color15 = "#E1E9E4";

      copy_on_select = "clipboard";
      clear_selection_on_clipboard_loss = true;

      enable_audio_bell = false;
      cursor_shape = "block";
      scrollback_lines = 15000;
      wheel_scroll_multiplier = 5;
      dynamic_window_title = true;
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_bar_min_tabs = 1;
      confirm_os_window_close = 0;
      hide_window_decorations = "yes";
      background_opacity = "0.98";
      window_padding_width = 0;
    };

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "shift+insert" = "paste_from_clipboard";
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+w" = "close_tab";
      "ctrl+tab" = "next_tab";
      "ctrl+shift+tab" = "previous_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "alt+\\" = "launch --location=hsplit";
      "ctrl+alt+\\" = "launch --location=vsplit";
      "ctrl+alt+enter" = "new_os_window";
      "ctrl+shift+f11" = "toggle_fullscreen";
      "ctrl+alt+h" = "neighboring_window left";
      "ctrl+alt+j" = "neighboring_window down";
      "ctrl+alt+k" = "neighboring_window up";
      "ctrl+alt+l" = "neighboring_window right";
    };
  };

  ## ------ neovide ------
  programs.neovide = {
    enable = true;
    package = pkgs.neovide;
    settings = {
      frame = if pkgs.stdenv.isDarwin then "transparent" else "none";
      maximized = true;
      tabs = false;
      title-hidden = pkgs.stdenv.isDarwin;
      vsync = true;

      font = {
        size = font_size;
        normal = [
          { family = myvars.fontFamily; }
          {
            family = "NotoMono Nerd Font Mono";
            style = "Normal";
          }
        ];
        bold = [
          {
            family = myvars.fontFamily;
            style = "Bold";
          }
        ];
        hinting = "full";
        edging = "antialias";
      };

      box-drawing = {
        mode = "native";
        sizes.default = [
          2
          4
        ];
      };
    };
  };

  ## ------ alacritty ------
  programs.alacritty = {
    enable = true;
    settings = {
      colors = {
        primary = {
          background = "#1f1f28";
          foreground = "#d8dfda";
        };
        normal = {
          black = "#1E1E1E";
          red = "#EC5F66";
          green = "#99C794";
          yellow = "#F9AE58";
          blue = "#6699CC";
          magenta = "#C695C6";
          cyan = "#5FB4B4";
          white = "#F0F1F0";
        };
        bright = {
          black = "#B4B4A6";
          red = "#F97B58";
          green = "#ACD1A8";
          yellow = "#FAC761";
          blue = "#85ADD6";
          magenta = "#D8B6D8";
          cyan = "#82C4C4";
          white = "#E1E9E4";
        };
        cursor = {
          cursor = "#f5e0dc";
          text = "#11111b";
        };
        selection = {
          background = "#585b70";
          text = "#d8dfda";
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
        size = font_size;
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
        blur = pkgs.stdenv.isDarwin;
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
