{
  pkgs,
  lib,
  config,
  inputs,
  username,
  homeDir,
  isDarwin,
  ...
}:

let
  isLinux = pkgs.stdenv.isLinux;
  rustupServer = "https://mirrors.tuna.tsinghua.edu.cn/rustup";
  conf = config.xdg.configHome;
  data = config.xdg.dataHome;
  cache = config.xdg.cacheHome;
  CARGO_HOME = data + "/cargo";
  GOPATH     = data + "/go";
  RUSTUP_HOME = data + "/rustup";
  cargo_bin = CARGO_HOME + "/bin";
  go_bin = GOPATH + "/bin";
  ## npm settings in npmrc
  npm_global_bin = data + "/npm-global/bin";
in
{
  home.stateVersion = "25.11";
  home.username = username;
  home.homeDirectory = homeDir;
  xdg.enable = true;
  programs.home-manager.enable = true;

  home.sessionVariables = {
    LESSHISTFILE = cache + "/less/history";
    LESSKEY      = conf + "/less/lesskey";

    inherit GOPATH CARGO_HOME RUSTUP_HOME;

    RUSTUP_DIST_SERVER = rustupServer;
    RUSTUP_UPDATE_ROOT = rustupServer + "/rustup";

    NPM_CONFIG_USERCONFIG = conf + "/npmrc";

    FZF_DEFAULT_COMMAND = "fd --exclude={.git,.idea,.vscode,tags,OrbStack} --type f";
    ## eza can find theme
    EZA_CONFIG_DIR = conf + "/eza";
  };

  home.sessionPath = [
    npm_global_bin
    cargo_bin
    go_bin
  ] ++ (lib.optionals isDarwin [
    "/opt/homebrew/bin"
  ]);

  imports = [
    ./tui
    inputs.my-dotzsh.homeManagerModules.default
    inputs.my-nvimdots.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    zoxide
    trash-cli
    fastfetch
    docker-compose
    docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
    nginx
    caddy
    sqlite
    acme-sh
    gh
    tea

    ## programming
    gnumake
    cmake
    go
    perl
    python3
    lua
    nodejs # provides node, npm
    rustup # provides rustfmt, cargo-clippy, rustup, cargo, rust-lldb, rust-analyzer, rustc, rust-gdb, cargo-fmt

    ## rust related
    # cargo-bloat # find what takes the most space in the executable
    # cargo-cache # manage cargo cache (${CARGO_HOME}); print and remove dirs selectively

    ## archives, compression and decompression
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

    ## utils
    ninja
    xclip
    fzf
    gnupg
    lrzsz
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    rsync
    lsof # list open files
    # direnv ## programs.direnv.enable = true
    just
    chase
    cachix # Command-line client for Nix binary cache hosting https://cachix.org
    tokei

    ## networking tools
    dnsutils  # `dig` + `nslookup`
    # ldns # replacement of `dig`, it provide the command `drill`
    ipcalc  # it is a calculator for the IPv4/v6 addresses
    pv
    nexttrace
    frp

    ## utilities written in Rust
    bandwhich
    bat # cat
    broot
    # delta # diff; also used of git ## programs.delta.enable = true
    dua
    duf # df
    dust # du; (`du-dust` name is depracated)
    eza # ls colorize more info
    fd # find
    hyperfine
    # miniserve
    ncdu
    procs # ps
    ripgrep # recursively searches directories for a regex pattern
    sd # sed
    stylua # lua format tool
    # tlrc # A tldr client written in Rust(conflit with programs.tealdeer.enable = true)
    tre-command
    uv # replace for pip
    # yazi # ranger ## programs.<name>.enable = true

    ## misc
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    axel
    mpv # yt-dlp
    doxygen
    tokei
    tree
    multitail
    tree-sitter # otherwise nvim complains that the binary 'tree-sitter' is not found
    ctags
    # w3m
    imagemagick
    ouch
    beszel
    fishPlugins.tide
    ## gui
    alacritty

    ## nix related
    # nh ## programs.nh.enable = true
    nil # language server for Nix
    nix-tree
    nixfmt
    nurl
    nix-output-monitor # it provides the command `nom` works just like `nix` with more details log output

    # productivity
    hugo # static site generator
    htop
    glow # markdown previewer in terminal
    btop  # replacement of htop/nmon
    iftop # network monitoring

    ## gnu tools
    gnumake
    gnused
    gnupg
    gnutar
  ] ++ (lib.optionals isLinux [
    strace # a diagnostic, debugging and instructional userspace utility for Linux.
    ltrace # library call monitoring
    pahole
    iotop # io monitoring
    stun
  ]) ++ (lib.optionals isDarwin [
    ## This is automatically setup on Linux
    gettext
  ]);
}
