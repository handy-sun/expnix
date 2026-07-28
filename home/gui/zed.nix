{
  lib,
  profileLevel,
  myvars,
  ...
}:

lib.mkIf profileLevel.guiBase {
  programs.zed-editor = {
    enable = true;

    ## Extensions auto-installed on startup (repo names from zed-industries/extensions).
    ## Most VSCode plugins (Rust, TS, YAML, git blame/history, outline, remote SSH/WSL,
    ## markdown preview, One Dark/Ayu themes) are native in Zed and need no extension.
    extensions = [
      # language support / LSP / syntax
      "nix" # jnoortheen.nix-ide + brettm12345.nixfmt-vscode
      "toml" # tamasfe.even-better-toml
      "xml" # dotjoshjohnson.xml
      "lua" # sumneko.lua + johnnymorganz.stylua
      "just" # kokakiwi.vscode-just
      "make" # ms-vscode.makefile-tools
      "neocmake" # CMake syntax + LSP (no native Zed support)
      "ninja" # surajbarkale.ninja
      "ini" # highlight vimrc/config files mapped in file_types below
      "ssh-config" # ms-vscode-remote.remote-ssh (~/.ssh/config highlighting)
      "linkerscript" # zixuanwang.linkerscript
      "assembly" # pengyifu.x8664assemblys
      "doxygen" # cschlosser.doxdocgen
      "powershell" # ms-vscode.powershell
      "log"
      # tooling
      "bookmark" # alefragnani.bookmarks
      "dependi" # fill-labs.dependi
      "rainbow-csv" # mechatroner.rainbow-csv + janisdd.vscode-edit-csv
      "git-firefly"
      "github-actions" # github.vscode-github-actions
      "docker-compose" # ms-azuretools.vscode-containers
      "dockerfile" # ms-azuretools.vscode-containers
      "colorizer" # kamikillerto.vscode-colorize
      # icon theme referenced by icon_theme setting below
      "catppuccin-icons" # vscode-icons-team.vscode-icons
    ];

    userSettings = {
      auto_update = false;
      ui_font_family = ".SystemUIFont";
      format_on_save = "off";
      outline_panel = { };
      collaboration_panel = { };
      git_panel = { };
      proxy = "";
      # relative_line_numbers = "wrapped";
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
      languages = {
        JavaScript.tab_size = 2;
        JSON.tab_size = 2;
        JSONC.tab_size = 2;
      };
      use_system_path_prompts = false;
      use_system_prompts = false;
      file_scan_exclusions = [
        "**/.git"
        "**/node_modules"
        "**/target"
        "**/.venv"
        "**/build"
      ];
      session = {
        restore_unsaved_buffers = true;
        trust_all_worktrees = false;
      };
      restore_on_startup = "last_session";
      title_bar.show_menus = true;
      line_ending = "enforce_lf";
      status_bar = {
        active_encoding_button = "enabled";
        line_endings_button = "true";
      };
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
