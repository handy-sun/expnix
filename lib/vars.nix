rec {
  user = "qi";

  langEnv = "zh_CN.UTF-8";

  userLocal = "$HOME/.local/share";

  ## common system enviroment
  commonEnv = {
    LANG = "${langEnv}";
    TERM = "xterm-256color";
    PAGER = "less";
    LESS = "-RX";
    ## for 'sudo -e'
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

}
