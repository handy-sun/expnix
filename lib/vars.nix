rec {
  user = "qi";
  homeDir = if "${user}" == "root" then "/root" else "/home/${user}";
  langEnv = "zh_CN.UTF-8";
  commonEnv = {
    LANG = "${langEnv}";
    TERM = "xterm-256color";
    PAGER = "less";
    LESS = "-RX";
    ## for 'sudo -e'
    EDITOR = "nvim";
    VISUAL = "nvim";
    RUSTUP_DIST_SERVER = "https://mirrors.tuna.tsinghua.edu.cn/rustup";
    RUSTUP_UPDATE_ROOT = "https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup";
    ## some XDG vars aren't set, the missing ones are now set according to the
    ## spec: (https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
    XDG_STATE_HOME = "$HOME/.local/state";
    XDG_CACHE_HOME = "$HOME/.cache";
  };
}