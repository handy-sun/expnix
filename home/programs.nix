{ inputs, config, pkgs, lib, ... }:

let
  dotfiles = inputs.my-dotfiles;
  dotconfig = "${dotfiles}/.config";
in
{
  home.activation = {
    ## If use git config at path: `~/.config/git/config`, `~/.gitconfig` should not exist!
    ## https://git-scm.com/docs/git-config#Documentation/git-config.txt---global
    removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f ${config.home.homeDirectory}/.gitconfig
    '';

    initMyDotzsh = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PATH="${config.home.profileDirectory}/bin:/run/current-system/sw/bin:\$PATH" bash ${inputs.my-dotzsh}/common.sh.in 1
    '';
  };

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
    plugins = {
      inherit (pkgs.yaziPlugins) git;
    };
  };
  xdg.configFile."yazi" = {
    source = "${dotconfig}/yazi";
    recursive = true;
  };

  ## ---------- zsh ----------
  home.file.".zshrc".text = ''
    source ${inputs.my-dotzsh}/zshrc

    if (( $+commands[zoxide] )); then
        eval "$(zoxide init zsh)"
    fi
  '';
}