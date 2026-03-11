{ lib, pkgs, ... }:

let
  myvars = import ../lib/vars.nix;
in
{
  nixpkgs = {
    hostPlatform = lib.mkDefault "aarch64-linux";
    config.allowUnfree = true; # allow non-FOSS pkgs
  };
  networking.hostName = lib.mkForce "expnix";
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      # dates = "Sun *-*-* 00:00:00";
      options = "--delete-older-than 7d";
    };
    settings = {
      # trusted-users = [ "${myvars.user}" ];
      # Optimise storage
      # you can also optimise the store manually via:
      #    nix-store --optimise
      # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
  users.extraGroups.docker.members = [ "${myvars.user}" ];

  environment.systemPackages = with pkgs; [
    git
    vim
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

    # system tools
    fail2ban
    sysstat
    logrotate
    lm_sensors # for `sensors` command
    ethtool
    openssl
    openssh
    pciutils # lspci
    usbutils # lsusb

    # networking tools
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

    # misc (about gnu)
    gnumake
    gnused
    gnutar
    gnupg
  ];
  environment = {
    # homeBinInPath = true;
    localBinInPath = true;
    sessionVariables = {
      ## for 'sudo -e'
      EDITOR = "nvim";
      VISUAL = "nvim";
      ## systemd
      SYSTEMD_PAGER = "nvim";
      SYSTEMD_EDITOR = "nvim";
      TERM = "xterm-256color";
      ## idk why, but some XDG vars aren't set, the missing ones are now set according to the
      ## spec: (https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_CACHE_HOME = "$HOME/.cache";
    };
  };

  ## must enable zsh in order users to use it
  programs.zsh.enable = true;
  users.users.${myvars.user}.shell = pkgs.zsh;

  time = {
    # timeZone =  "Asia/Shanghai";
    hardwareClockInLocalTime = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ALL = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
    };
  };
}
