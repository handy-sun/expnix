{ pkgs, ... }:

{
  # home.stateVersion = "26.05";
  home.stateVersion = "25.11";
  home.username = "qi";
  home.homeDirectory = "/home/qi";

  imports = [
    ./programs.nix
  ];

  home.packages = with pkgs; [
    zoxide
    trash-cli
    neofetch
    fastfetch
    neovim
    docker-compose
    docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
    nginx
    caddy
    acme-sh

    ## programming
    # clang gcc confilct ? /nix/store/.../bin/cpp
    (pkgs.buildEnv {
      name = "dev-cpp";
      paths = with pkgs; [
        gcc
        clang
      ];
      ignoreCollisions = true;
    })
    gnumake
    cmake
    go
    perl
    python3
    lua
    nodejs # provides node, npm
    rustup # provides rustfmt, cargo-clippy, rustup, cargo, rust-lldb, rust-analyzer, rustc, rust-gdb, cargo-fmt

    ## debugging
    gdb
    pahole
    strace # a diagnostic, debugging and instructional userspace utility for Linux.
    ltrace # library call monitoring
    lsof # list open files

    ## rust related
    # cargo-bloat # find what takes the most space in the executable
    # cargo-cache # manage cargo cache (${CARGO_HOME}); print and remove dirs selectively

    # archives, compression and decompression
    bzip2
    cpio # Program to create or extract from cpio archives
    gzip
    p7zip
    pigz # Parallel Implementation of GZip
    # rar # absent on aarch64, and not really needed
    unzip
    unrar-free
    xz
    zip
    zstd

    # utils
    ninja
    xclip
    fzf
    gnupg
    lrzsz
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    rsync
    stun

    # networking tools
    dnsutils  # `dig` + `nslookup`
    # ldns # replacement of `dig`, it provide the command `drill`
    ipcalc  # it is a calculator for the IPv4/v6 addresses
    pv
    nexttrace

    # utilities written in Rust
    bandwhich
    bat # cat
    broot
    delta # diff; also used of git
    dua
    duf # df
    dust # du; (`du-dust` name is depracated)
    eza # ls colorize more info
    fd # find
    hyperfine
    miniserve
    ncdu
    procs # ps
    ripgrep # recursively searches directories for a regex pattern
    sd # sed
    stylua # lua format tool
    tlrc # A tldr client written in Rust
    tre-command
    uv # pip
    yazi # ranger

    # misc
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    axel
    yt-dlp
    doxygen
    tree
    multitail
    tree-sitter # otherwise nvim complains that the binary 'tree-sitter' is not found
    ctags
    w3m
    imagemagick

    ## nix related
    nh # another nix cli helper
    nil # language server for Nix
    nix-tree
    nix-output-monitor # it provides the command `nom` works just like `nix` with more details log output

    # productivity
    hugo # static site generator
    htop
    glow # markdown previewer in terminal
    btop  # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring
  ];

  home.sessionVariables = {
    TERM = "xterm-256color";
    PAGER = "less";
    LESS = "-RX";
    RUSTUP_DIST_SERVER = "https://rsproxy.cn";
    RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";
  };

}
