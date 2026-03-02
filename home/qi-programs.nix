{ inputs, pkgs, lib, ... }:

let
  dotfiles = inputs.my-dotfiles;
in
{
  ## ---------- yazi ----------
  programs.yazi = {
    enable = true;
    plugins = {
      inherit (pkgs.yaziPlugins) git;
    };
  };
  xdg.configFile."yazi" = {
    source = "${dotfiles}/.config/yazi";
    recursive = true;
  };
}