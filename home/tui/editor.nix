{
  lib,
  pkgs,
  inputs,
  isDarwin,
  isHmSingle,
  ...
}:
let
  isNeedBuildEnv = !isDarwin && !isHmSingle;
in
{
  ## Use `xdg.configFile."vim/"` instead of programs.vim
  xdg.configFile = {
    "vim/vimrc".source = inputs.my-dotvim + "/vimrc";
    "vim/user2.vim".source = inputs.my-dotvim + "/user2.vim";
  };

  programs.neovim.nvimdots = {
    enable = true;
    bindLazyLock = false;
    setBuildEnv = isNeedBuildEnv; # Only needed for NixOS
    withBuildTools = isNeedBuildEnv; # Only needed for NixOS
  };

  programs.helix = {
    enable = true;

    settings = {
      theme = "autumn_night_transparent";
      editor = {
        line-number = "relative";
        cursorline = true;
        color-modes = true;
        auto-completion = true;
        auto-info = true;
        auto-format = false;
        auto-save = true;
        scrolloff = 3;
        mouse = true;
        search.smart-case = true;
        lsp.display-messages = true;
        lsp.display-inlay-hints = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        statusline = {
          left = [
            "mode"
            "file-name"
            "file-modification-indicator"
            "file-type"
            "separator"
            "selections"
          ];
          center = [
            "diagnostics"
            "workspace-diagnostics"
            "separator"
            "file-encoding"
            "spacer"
            "file-line-ending"
          ];
          right = [
            "position"
            "total-line-numbers"
            "position-percentage"
          ];
          mode.normal = "NORMAL";
          mode.insert = "INSERT";
          mode.select = "SELECT";
        };
        # indent-guides.render = true;
      };
      keys.normal = {
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
        ins = "insert_mode";
        a = [
          "move_char_right"
          "insert_mode"
        ];
        p = "paste_clipboard_before";
        y = "yank_main_selection_to_clipboard";
        C-j = [ "save_selection" ];
        C-r = ":reload";
        space = {
          space = "file_picker";
          q = ":q";
          backspace = ":qa!";
          "2" = ":w";
          "." = "file_picker_in_current_buffer_directory";
          "/" = "toggle_comments";
        };
      };
    };

    languages.language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = lib.getExe pkgs.nixfmt;
      }
    ];

    themes = {
      autumn_night_transparent = {
        "inherits" = "autumn_night";
        # "ui.background" = { };
        "ui.statusline" = {
          fg = "gold";
          bg = "black";
        };
      };
    };
  };
}
