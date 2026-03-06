{ lib, pkgs, ... }:

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
      trusted-users = [ "qi" ];
      # Optimise storage
      # you can also optimise the store manually via:
      #    nix-store --optimise
      # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
    wget
    file
    rsync
    dae
    glider
    sing-box
    zsh
    tmux
    docker
    docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
    docker-compose
    ctags
    stun
    zerotierone
    acme-sh
    lrzsz

    ## programming
    clang
    gcc
    go
    cmake
    perl
    python3
    lua
    nodejs # provides node, npm

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    fail2ban
    sysstat
    logrotate
    lm_sensors # for `sensors` command
    ethtool
    openssl
    pciutils # lspci
    usbutils # lsusb

    # networking tools
    frp
    iperf3
    dnsmasq # Integrated DNS, DHCP and TFTP server for small networks
    dnsutils  # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses
    iproute2
    pv

    ## rust related
    # cargo-bloat # find what takes the most space in the executable
    # cargo-cache # manage cargo cache (${CARGO_HOME}); print and remove dirs selectively
    # cargo-zigbuild
    rustup # provides rustfmt, cargo-clippy, rustup, cargo, rust-lldb, rust-analyzer, rustc, rust-gdb, cargo-fmt

    ## nix related
    nix-tree
    nix-output-monitor # it provides the command `nom` works just like `nix` with more details log output

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

  boot = {
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    };
  };

  # must enable zsh in order users to use it [[1
  programs.zsh.enable = true;
  users.users.qi = {
    shell = pkgs.zsh;
  };
  # ]]1
  users.extraGroups.docker.members = [ "qi" ];

  time = {
    timeZone = lib.mkForce "Asia/Shanghai";
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
