{
  lib,
  profileLevel,
  myvars,
  ...
}:

lib.mkIf profileLevel.guiBase {
  programs.zed-editor = {
    enable = true;

    userSettings = {
      ui_font_family = ".SystemUIFont";
      format_on_save = "off";
      outline_panel = { };
      collaboration_panel = { };
      git_panel = { };
      proxy = "";
      relative_line_numbers = "wrapped";
      icon_theme = {
        mode = "light";
        light = "Catppuccin Mocha";
        dark = "Catppuccin Macchiato";
      };
      buffer_line_height = {
        custom = 1.3;
      };
      agent = {
        default_profile = "ask";
        dock = "right";
        default_model = {
          effort = "HIGH";
          provider = "zed.dev";
          model = "gemini-3.5-flash";
          enable_thinking = true;
        };
        favorite_models = [ ];
        model_parameters = [ ];
      };
      context_servers = {
        mcp-server-context7 = {
          enabled = true;
          remote = false;
          settings = {
            context7_api_key = "";
          };
        };
        mcp-server-github = {
          enabled = true;
          remote = false;
          settings = {
            github_personal_access_token = "GITHUB_PERSONAL_ACCESS_TOKEN";
          };
        };
      };
      buffer_font_weight = 300.0;
      vim_mode = false;
      terminal = {
        font_size = 15.0;
        font_family = "${myvars.fontFamily}";
        font_fallbacks = [
          "NotoMono Nerd Font Mono"
          "SF Mono"
          "Consolas"
        ];
        max_scroll_history_lines = 9000;
      };
      project_panel = {
        default_width = 240.0;
        dock = "left";
        auto_reveal_entries = false;
      };
      base_keymap = "VSCode";
      minimap = {
        show = "never";
      };
      buffer_font_fallbacks = [
        "NotoMono Nerd Font Mono"
        "SF Mono"
        "monospace"
      ];
      buffer_font_family = "Maple Mono NF CN";
      file_types = {
        ini = [
          "default"
          "vimrc"
          "config"
        ];
        xml = [ "*.plist" ];
        yaml = [ "*.yml" ];
        asm = [ "*.S" ];
        toml = [ "*.toml" ];
      };
      show_whitespaces = "all";
      soft_wrap = "editor_width";
      hard_tabs = false;
      tab_size = 4;
      ui_font_size = 17.0;
      buffer_font_size = 15.0;
      theme = {
        mode = "dark";
        light = "Ayu Mirage";
        dark = "One Dark";
      };
    };
  };
}
