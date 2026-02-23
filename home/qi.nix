{ config, pkgs, ... }:

{
  # remember to modify
  home.username = "qi";
  home.homeDirectory = "/home/qi";

  home.packages = with pkgs;[
    zsh
    tmux
    zoxide
    rsync
    docker
    docker-compose
    neovim
    trash-cli
    caddy
    neofetch
    fastfetch
    # nnn # terminal file manager
    gcc
    # cmake
    python3
    lua

    # archives
    zip
    xz
    unzip
    p7zip
    pigz

    # utils
    fzf
    jq # A lightweight and flexible command-line JSON processor
    # utilities written in Rust
    ripgrep # recursively searches directories for a regex pattern
    yq-go # yaml processor https://github.com/mikefarah/yq
    eza
    fd
    bat
    yazi
    delta
    dust
    duf
    uv
    sd
    stylua
    dua
    ncdu
    hyperfine

    # networking tools
    iperf3
    dnsutils  # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses
    iproute2
    pv

    # misc
    tree
    multitail
    gnused
    gnutar
    gawk
    gnupg
    poppler-utils
    nil # language server for Nix
    tree-sitter # otherwise nvim complains that the binary 'tree-sitter' is not found
    nodejs-slim_25

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    # productivity
    hugo # static site generator
    glow # markdown previewer in terminal
    btop  # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
  ];

  programs.git = {
    enable = false;
  };

  # programs.zsh.enable = true;
  home.file.".zshrc".text = ''
    source $HOME/.config/dotzsh/zshrc
  '';
  home.stateVersion = "26.05";
}
