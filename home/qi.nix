{ pkgs, ... }:

{
  # remember to modify
  home.username = "qi";
  home.homeDirectory = "/home/qi";

  home.packages = with pkgs; [
    zoxide
    trash-cli
    caddy
    neofetch
    fastfetch
    # nnn # terminal file manager

    # language of coding
    gcc
    go
    # cmake
    python3
    lua
    nodejs_25
    # nodejs-slim_25

    # archives, compression and decompression
    bzip2
    gzip
    p7zip
    pigz # Parallel Implementation of GZip
    #rar # absent on aarch64, and not really needed
    unzip
    unrar # non-FOSS(unfree) pkgs !!!
    xz
    zip
    zstd

    # utils
    fzf
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq

    # utilities written in Rust
    bandwhich
    bat # cat
    bottom
    broot
    delta # diff; also used of git
    dua
    duf # df
    dust # du; (`du-dust` name is depracated)
    eza # ls colorize more info
    fd # find
    hyperfine
    ncdu
    procs # ps
    ripgrep # recursively searches directories for a regex pattern
    sd # sed
    stylua # lua format tool
    tre-command
    uv # pip
    yazi # ranger

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
    tree-sitter # otherwise nvim complains that the binary 'tree-sitter' is not found

    # productivity
    hugo # static site generator
    htop
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

    ## rust related
    # cargo-bloat # find what takes the most space in the executable
    # cargo-cache # manage cargo cache (${CARGO_HOME}); print and remove dirs selectively
    # cargo-zigbuild
    # rustup # provides rustfmt, cargo-clippy, rustup, cargo, rust-lldb, rust-analyzer, rustc, rust-gdb, cargo-fmt

    # nix related
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor
    nil # language server for Nix
  ];

  programs.git = {
    enable = false;
  };

  home.file.".zshrc".text = ''
    source $HOME/.config/dotzsh/zshrc
  '';
  home.stateVersion = "26.05";
}
