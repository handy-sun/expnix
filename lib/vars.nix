rec {
  user = "qi";
  group = "users";
  langEnv = "zh_CN.UTF-8";

  ## common system environment
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

  ## System packages shared across NixOS and darwin.
  ## Attribute name strings — resolved to packages at call sites.
  systemCommonPkgs = [
    "vim"
    "git"
    "neovim"
    "curl"
    "cron"
    "wget"
    "fail2ban"
    "file"
    "lsof"
    "perl"
    "xz"
    "zstd"
    "procps"
    "fakeroot"
    "openssl"
    "openssh"
    "nmap"
    "logrotate"
    "nginx"
    "sing-box"
    "smartmontools"
    "pciutils"
    "usbutils"
    "iperf3"
    "tcpdump"
    "dnsmasq"
    "ldns"
    "socat"
    "zoxide"
  ];

  ## Profile level defaults — hosts can override.
  ## tuibase has no key: always included.
  profileLevel = {
    tuiAdvanced = true;
    tuiOptional = false;
    guiBase = false;
    guiHeavy = false;
  };

  reinsvpsNetwork = {
    ipv4Address = "103.149.93.96";
  };

  ## Fonts shared across NixOS and darwin.
  ## Attribute name strings — resolved to packages at call sites.
  fontsPkgs = [
    "maple-mono.NF-CN"
    "source-sans"
    ## China, JP, Korea
    "noto-fonts-cjk-sans"
    "noto-fonts-cjk-serif"
    ## suitable
    "fira-code"
    "jetbrains-mono"
    ## icon fonts
    "material-design-icons"
    "font-awesome"
    ## https://github.com/NixOS/nixpkgs/blob/nixos-unstable-small/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
    "nerd-fonts.symbols-only"
    "nerd-fonts.fira-code"
    "nerd-fonts.jetbrains-mono"
    "nerd-fonts.noto"
  ];

  fontFamily = "Maple Mono NF CN";

  qimocha = {
    foreground = "#c5ccc7";
    background = "#1f1f28";
    cursor_bg = "#f5e0dc";
    cursor_border = "#f5e0dc";
    cursor_fg = "#11111b";
    selection_bg = "#585b70";
    selection_fg = "#c5ccc7";
    ansi = [
      "#1E1E1E"
      "#EC5F66"
      "#99C794"
      "#F9AE58"
      "#6699CC"
      "#C695C6"
      "#5FB4B4"
      "#DFE0DF"
    ];
    brights = [
      "#B4B4A6"
      "#F97B58"
      "#ACD1A8"
      "#FAC761"
      "#85ADD6"
      "#D8B6D8"
      "#82C4C4"
      "#CDD5D1"
    ];
  };

  domain = "647792.xyz";
}
