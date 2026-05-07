{
  pkgs,
  lib,
  myvars,
  homeDir,
  myutils,
  profileLevel,
  ...
}:
{
  disabledModules = [ "services/networking/sing-box.nix" ];

  imports = myutils.scanPaths ./. ++ [ (myutils.relativeToRoot "modules/sing-box") ];

  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
    curl
    wget
    file
    fish
    zsh
    tmux
    docker
    zerotierone
    acme-sh
    gcc
    perl
    zstd
    zip
    unzip
    xz
    nginx
    strace # a diagnostic, debugging and instructional userspace utility for Linux.
    lsof # list open files
    procps
    fakeroot
    cron

    ## system tools
    fail2ban
    sysstat
    logrotate
    lm_sensors # for `sensors` command
    ethtool
    openssl
    openssh
    pciutils # lspci
    usbutils # lsusb
    smartmontools

    ## networking tools
    dae
    glider
    sing-box
    frp
    iperf3
    dnsmasq # Integrated DNS, DHCP and TFTP server for small networks
    ldns # replacement of `dig`, it provide the command `drill`
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    iproute2
    iptables
  ];

  environment = {
    localBinInPath = true;
    sessionVariables = myvars.commonEnv // {
      ## For Linux
      SYSTEMD_PAGER = "nvim";
      SYSTEMD_EDITOR = "nvim";
    };
  };

  programs.zsh.enable = true;
  programs.fish.enable = true;
  users.users.${myvars.user} = {
    home = lib.mkDefault homeDir;
    createHome = lib.mkDefault true;
    shell = pkgs.fish;
  };

  users.extraGroups.docker.members = [ "${myvars.user}" ];

  time = {
    hardwareClockInLocalTime = true;
    timeZone = lib.mkForce "Asia/Shanghai";
  };

  i18n = {
    defaultLocale = "${myvars.langEnv}";
    extraLocaleSettings = {
      LC_ALL = "${myvars.langEnv}";
    };

    ## Fcitx5 input method for Chinese input on Wayland
    inputMethod = lib.mkIf profileLevel.guiBase {
      enable = true;
      type = "fcitx5";
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        ## pinyin
        qt6Packages.fcitx5-chinese-addons
        fcitx5-gtk
      ];
    };
  };

  fonts = lib.mkIf profileLevel.guiBase {
    packages = myutils.resolveNames pkgs myvars.fontsPkgs;
    fontconfig = {
      defaultFonts = {
        monospace = [ "Noto Sans Mono CJK SC" ];
        sansSerif = [ "Noto Sans CJK SC" ];
      };
      hinting = {
        enable = true;
        style = "slight";
      };
      antialias = true;
    };
  };
}
