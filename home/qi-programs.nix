{ inputs, config, pkgs, lib, ... }:

let
  dotfiles = inputs.my-dotfiles;
  dotconfig = "${dotfiles}/.config";
in
{
  ## If use git config at path: `~/.config/git/config`, to make git use this config file, `~/.gitconfig` should not exist!
  ## https://git-scm.com/docs/git-config#Documentation/git-config.txt---global
  home.activation = {
    removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      test -e ${config.home.homeDirectory}/.gitconfig && rm -f ${config.home.homeDirectory}/.gitconfig
    '';

    initMyDotzsh = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      bash ${inputs.my-dotzsh}/common.sh.in
    '';
  };

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

  ## ---------- zsh ----------
  # home.file.".zshrc".text = "source ${config.xdg.configHome}/zsh/zshrc";
  home.file.".zshrc".text = ''
    source $HOME/.config/dotzsh/zshrc
  '';
}