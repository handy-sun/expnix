{
  lib,
  pkgs,
  inputs,
  isDarwin,
  isHmSingle,
  ...
}:
let
  isNeedBuildEnv = (!isDarwin && !isHmSingle);
in
{
  ## Use `xdg.configFile."vim/"` instead of programs.vim
  xdg.configFile = {
    "vim/vimrc".source     = inputs.my-dotvim + "/vimrc";
    "vim/user2.vim".source = inputs.my-dotvim + "/user2.vim";
  };

  programs.neovim.nvimdots = {
    enable = true;
    setBuildEnv = isNeedBuildEnv;  # Only needed for NixOS
    withBuildTools = isNeedBuildEnv; # Only needed for NixOS
  };

  programs.helix = {
    enable = true;

    settings = {
      theme = "autumn_night";
      editor = {
        line-number = "relative";
        cursorline = true;
        color-modes = true;
        lsp.display-messages = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides.render = true;
     };
    };

    languages.language = [{
      name = "nix";
      auto-format = true;
      formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
    }];
  };
}