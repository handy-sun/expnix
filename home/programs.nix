{ inputs, config, pkgs, lib, ... }:

let
  dotfiles = inputs.my-dotfiles;
  dotconfig = "${dotfiles}/.config";
in
{
  imports = [
    inputs.my-dotzsh.homeManagerModules.default
  ];

  programs.home-manager.enable = true;

  xdg.configFile."alacritty".source = "${dotconfig}/alacritty";
  xdg.configFile."bat".source = "${dotconfig}/bat";
  xdg.configFile."clangd".source = "${dotconfig}/clangd";
  xdg.configFile."eza".source = "${dotconfig}/eza";
  xdg.configFile."git".source = "${dotconfig}/git";
  xdg.configFile."go".source = "${dotconfig}/go";
  xdg.configFile."mpv".source = "${dotconfig}/mpv";
  xdg.configFile."tmux".source = "${dotconfig}/tmux";

  programs.git.ignores = [
    "__pycache__"
    ".DS_Store"
  ];

  ## ---------- yazi ----------
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    plugins = {
      inherit (pkgs.yaziPlugins) git;
    };
  };
  xdg.configFile."yazi" = {
    source = "${dotconfig}/yazi";
    recursive = true;
  };

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
  };
  programs.dotzsh = {
    enable = true;
    enableSourceZshrc = true;
  };
}
