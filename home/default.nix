{
  pkgs,
  lib,
  config,
  inputs,
  username,
  myvars,
  homeDir,
  isWSL,
  isDarwin,
  isHmSingle,
  ...
}:
let
  isLinux = pkgs.stdenv.isLinux;
  rustupServer = "https://mirrors.tuna.tsinghua.edu.cn/rustup";
  conf = config.xdg.configHome;
  data = config.xdg.dataHome;
  cache = config.xdg.cacheHome;
  CARGO_HOME = data + "/cargo";
  GOPATH = data + "/go";
  RUSTUP_HOME = data + "/rustup";
  cargo_bin = CARGO_HOME + "/bin";
  go_bin = GOPATH + "/bin";
  local_bin = config.home.homeDirectory + "/.local/bin";
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
    LESSKEY = conf + "/less/lesskey";

    inherit GOPATH CARGO_HOME RUSTUP_HOME;

    RUSTUP_DIST_SERVER = rustupServer;
    RUSTUP_UPDATE_ROOT = rustupServer + "/rustup";
    UV_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple/";

    NPM_CONFIG_USERCONFIG = conf + "/npmrc";

    ## eza can find theme
    EZA_CONFIG_DIR = conf + "/eza";
    COLORTERM = "truecolor";
  }
  // myvars.homeEnv
  // lib.optionalAttrs isWSL {
    LD_LIBRARY_PATH = "/usr/lib/wsl/lib:\${LD_LIBRARY_PATH}";
  };

  home.sessionPath = [
    npm_global_bin
    cargo_bin
    go_bin
  ]
  ++ (lib.optionals isDarwin [
    local_bin
    "/opt/homebrew/bin"
  ]);

  imports = [
    ./tui
    inputs.my-dotzsh.homeManagerModules.default
    inputs.my-nvimdots.homeManagerModules.default
  ];

  home.packages =
    with pkgs;
    [
      zoxide
      trash-cli
      fastfetch
      docker-compose
      docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
      nginx
      caddy
      sqlite
      acme-sh
      git-filter-repo
      gh
      tea

      ## programming
      gnumake
      cmake
      go
      perl
      php
      python3
      lua
      nodejs # provides node, npm
      pnpm
      php

      ## archives, compression and decompression
      bzip2
      cpio # Program to create or extract from cpio archives
      gzip
      p7zip
      pigz # Parallel Implementation of GZip
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
      just
      chase
      cachix # Command-line client for Nix binary cache hosting https://cachix.org
      tokei

      ## networking tools
      dnsutils # `dig` + `nslookup`
      # ldns # replacement of `dig`, it provide the command `drill`
      ipcalc # it is a calculator for the IPv4/v6 addresses
      pv
      nexttrace
      frp

      ## utilities written in Rust
      bandwhich
      bat # cat
      broot
      duf # df
      dust # du; (`du-dust` name is depracated)
      eza # ls colorize more info
      fd # find
      hyperfine
      miniserve
      ncdu
      ouch
      procs # ps
      ripgrep # recursively searches directories for a regex pattern
      sd # sed
      stylua # lua format tool
      tre-command
      uv # replace for pip

      ## misc
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      axel
      beszel
      devenv
      doxygen
      tokei
      tree
      multitail
      tree-sitter # otherwise nvim complains that the binary 'tree-sitter' is not found
      just-lsp
      lua-language-server
      rust-analyzer
      ctags
      imagemagick
      ffmpeg
      shellcheck
      util-linux
      fishPlugins.tide
      fishPlugins.sponge
      fishPlugins.autopair

      ## nix related
      nil # language server for Nix
      nix-info
      nix-init
      nix-tree
      nixfmt
      alejandra
      nurl

      # productivity
      hugo # static site generator
      htop
      glow # markdown previewer in terminal
      btop # replacement of htop/nmon
      iftop # network monitoring

      ## gnu tools
      gnumake
      gnupg
      # gnutar ## (macos)vscode.remode-ssh bug

      ## has gui
      alacritty
      mpv
    ]
    ++ lib.optionals isHmSingle [
      rustc
      cargo
    ]
    ++ lib.optionals (!isHmSingle) [
      rust-bin.stable.latest.default # like rustup, not contain rust-analyzer
    ]
    ++ lib.optionals isLinux [
      strace # a diagnostic, debugging and instructional userspace utility for Linux.
      ltrace # library call monitoring
      pahole
      iotop # io monitoring
      stun
      libtree
      wezterm
      mpv
      fio
      ioping
    ]
    ++ lib.optionals isDarwin [
      xquartz
      ## This is automatically setup on Linux
      gettext
      gnused
    ];
}
