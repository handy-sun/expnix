{
  lib,
  config,
  pkgs,
  ...
}:
let
  xdgGitConfDir = config.xdg.configHome + "/git";
  homeGitConfig = config.home.homeDirectory + "/.gitconfig";
  backupFileExt = "$(date \"+%m%d-%H%M%S\").bak";
  nvimPath = lib.getExe pkgs.neovim;
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
      core.editor = nvimPath;
      core.quotepath = false;

      push.autoSetupRemote = true;
      pull.rebase = true;
      rebase.autostash = true;
      init.defaultBranch = "main";
      fetch.prune = true;

      diff.colorMoved = "default";
      diff.tool = "nvimdiff";
      difftool.prompt = false;
      difftool.stack = true;

      # merge.conflictstyle = "diff3";
      merge.tool = "nvimd-3w";
      mergetool.prompt = true;
      mergetool.keepBackup = false;
      mergetool."nvimd-3w".cmd = "nvim -d \"$LOCAL\" \"$MERGED\" \"$REMOTE\" -c \"wincmd =\"";

      url = {
        "https://github.com/" = {
          insteadOf = [
            "gh:"
            "ghro:"
          ];
        };
        "https://codeberg.org/" = {
          insteadOf = [
            "bg:"
            "bgro:"
          ];
        };
        # "ssh://git@github.com/" = {
        #   insteadOf = "ghp:";
        #   pushInsteadOf = "gh:";
        # };
        "ssh://git@github.com/" = {
          pushInsteadOf = "https://github.com/";
        };
        "ssh://git@codeberg.org/" = {
          insteadOf = "bgp:";
          pushInsteadOf = "bg:";
        };
        "___PUSH_DISABLED___" = {
          pushInsteadOf = [
            "ghro:"
            "bgro:"
          ];
        };
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = false;
      # diff-so-fancy = true;
      line-numbers = true;
      true-color = "always";
      minus-style = "syntax #3a1f24";
      minus-emph-style = "syntax #5a2a32";
      plus-style = "syntax #1f3a28";
      plus-emph-style = "syntax #2a5a38";
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
