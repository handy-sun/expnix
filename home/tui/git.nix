{
  lib,
  config,
  ...
}:
let
  xdgGitConfDir = config.xdg.configHome + "/git";
  homeGitConfig = config.home.homeDirectory + "/.gitconfig";
  backupFileExt = "$(date \"+%m%d-%H%M%S\").bak";
in
{
  ## `~/.gitconfig` should not exist!
  ## use `test -L`: maybe old settings `xdg.configFile."git"` cause some conflict error.
  home.activation.backUpExistingGitConfLink = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    test -f ${homeGitConfig} && mv ${homeGitConfig}{,_${backupFileExt}}
    test -L ${xdgGitConfDir} && mv ${xdgGitConfDir}{,_${backupFileExt}}
  '';

  programs.git = {
    enable = true;
    ignores = [
      "__pycache__"
      ".DS_Store"
    ];

    settings = {
      user.name = "sooncheer";
      user.email = "handy-sun@foxmail.com";

      core.autocrlf = false;
      core.safecrlf = true;
      core.editor = "nvim";

      push.autoSetupRemote = true;
      pull.rebase = true;
      rebase.autostash = true;
      init.defaultBranch = "main";

      diff.colorMoved = "default";
      diff.tool = "nvimdiff";
      "difftool \"nvimdiff\"".cmd = "nvim -d \"$LOCAL\" \"$REMOTE\"";
      difftool.prompt = false;
      difftool.stack = true;

      merge.conflictstyle = "diff3";
      merge.tool = "nvimdiff";
      "mergetool \"nvimdiif\"".cmd = "nvim -d \"$LOCAL\" \"$BASE\" \"$REMOTE\" \"$MERGED\" -c \"wincmd J\"";
      mergetool.prompt = true;
      mergetool.keepBackup = false;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;

      diff-so-fancy = true;
      line-numbers = true;
      true-color = "always";
      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-decoration-style = "none";
        file-style = "bold yellow ul";
      };
      features = "decorations";
      whitespace-error-style = "22 reverse";
    };
  };

  programs.lazygit.enable = true;
}