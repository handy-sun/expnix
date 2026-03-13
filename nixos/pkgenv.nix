{ lib, pkgs, ... }:

let
  myvars = import ../lib/vars.nix;
in
{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  networking.hostName = lib.mkForce "expnix";

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
    sessionVariables =
      myvars.commonEnv
      // { ## For Linux
        SYSTEMD_PAGER = "nvim";
        SYSTEMD_EDITOR = "nvim";
      };
  };

  ## must enable zsh in order users to use it
  programs.zsh.enable = true;
  users.users.${myvars.user}.shell = pkgs.zsh;

  time = {
    hardwareClockInLocalTime = true;
  };

  i18n = {
    defaultLocale = "${myvars.langEnv}";
    extraLocaleSettings = {
      LC_ALL = "${myvars.langEnv}";
    #   LC_CTYPE = "en_US.UTF-8";
    };
  };
}
