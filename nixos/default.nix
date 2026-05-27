{
  pkgs,
  lib,
  myvars,
  homeDir,
  myutils,
  networkingVars,
  profileLevel,
  ...
}:
let
  inherit (lib) mkDefault;
  commonSystemPackages = myutils.resolveNames pkgs myvars.systemCommonPkgs;
in
{
  imports = myutils.scanPaths ./.;

  programs.nix-ld.enable = true;

  environment.systemPackages =
    commonSystemPackages
    ++ (with pkgs; [
      docker
      zerotierone
      acme-sh
      gcc
      strace # a diagnostic, debugging and instructional userspace utility for Linux.

      ## system tools
      sysstat
      ethtool
      lm_sensors # for `sensors` command

      ## networking tools
      dae
      glider
      iproute2
      iptables
    ]);

  environment = {
    localBinInPath = true;
    sessionVariables = myvars.commonEnv // {
      ## For Linux
      SYSTEMD_PAGER = "nvim";
      SYSTEMD_EDITOR = "nvim";
    };
  };

  networking.hosts = networkingVars.hostsFile;
  networking.search = lib.mkAfter [ "orb.local" ];
  programs.ssh.knownHosts = networkingVars.ssh.knownHosts;

  programs.zsh.enable = true;
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;
  users.users.${myvars.user} = {
    home = homeDir;
    createHome = true;
    group = mkDefault "users";
    hashedPassword = "$6$rgT4Zw3CMO04LwFY$6L5MfeKp9/wsVXHNSylpN3H8xUgEpZmQNM6QIvPk2kSDR2VGxqCUwga8IpaWxYhuuVRY.4uJPlLpWl7hrsjtw0";
    isNormalUser = mkDefault true;
    extraGroups = mkDefault [
      "wheel"
    ];
    openssh.authorizedKeys.keys = networkingVars.userAuthorizedKeys;
  };

  users.extraGroups.docker.members = [ "${myvars.user}" ];

  security.sudo.wheelNeedsPassword = false;

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
