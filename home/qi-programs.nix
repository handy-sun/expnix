{ inputs, pkgs, lib, ... }:

let
  dotfiles = inputs.my-dotfiles;
  dotconfig = "${dotfiles}/.config";
in
{
  xdg.configFile."bat".source = "${dotconfig}/bat";
  xdg.configFile."clangd".source = "${dotconfig}/clangd";
  xdg.configFile."eza".source = "${dotconfig}/eza";
  xdg.configFile."git".source = "${dotconfig}/git";
  xdg.configFile."go".source = "${dotconfig}/go";
  xdg.configFile."mpv".source = "${dotconfig}/mpv";
  xdg.configFile."tmux".source = "${dotconfig}/tmux";
  ## ---------- yazi ----------
  programs.yazi = {
    enable = true;
    plugins = {
      inherit (pkgs.yaziPlugins) git;
    };
  };
  xdg.configFile."yazi" = {
    source = "${dotconfig}/yazi";
    recursive = true;
  };
}