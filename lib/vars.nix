# { lib }:
rec {
  user = "qi";

  langEnv = "zh_CN.UTF-8";

  ## common system enviroment
  commonEnv = {
    LANG = "${langEnv}";
    PAGER = "less";
    LESS = "-RX";
  };

  homeEnv = {
    TERM = "xterm-256color";
    ## for 'sudo -e'
    EDITOR = "nvim";
    VISUAL = "nvim";
    FZF_DEFAULT_COMMAND = "fd --exclude={.git,.idea,.vscode,tags,OrbStack} --type f";
  };

  ## Profile level defaults — hosts can override.
  ## tuibase has no key: always included.
  profileLevel = {
    tuiAdvanced = true;
    tuiOptional = false;
    guiBase = false;
    guiHeavy = false;
  };
}
