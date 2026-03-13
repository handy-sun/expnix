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
  };
}