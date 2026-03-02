{ config, pkgs, ... }:

let
  dotfiles = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/subtrees/dotfiles";
  # dotfiles = config.lib.file.mkOutOfStoreSymlink "../subtrees/dotfiles";
in
{
  ## ---------- yazi ----------
  programs.yazi = {
    enable = true;
    # plugins = {
    #   inherit (pkgs.yaziPlugins) git;
    # };
  };
  xdg.configFile."yazi" = {
    source = "${dotfiles}/.config/yazi";
    recursive = true;
  };
}