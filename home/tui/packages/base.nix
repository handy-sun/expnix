## ============================================================
## tuibase — always included: essential terminal tools for SSH
## ============================================================
{
  pkgs,
  isDarwin,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      ## build tools
      gnumake
      cmake
      ninja

      ## Docker
      docker-compose

      ## shell / navigation
      tmux
      zoxide
      trash-cli
      fastfetch
      fzf
      fd
      ripgrep
      bat
      eza
      broot

      ## JSON / YAML
      jq
      yq-go

      ## system monitoring
      htop
      procs
      btop
      duf
      dust

      ## file ops
      rsync
      lsof
      tree
      just
      gnupg
      util-linux

      ## archives (basics)
      gzip
      unzip
      xz
      zip
      bzip2
      zstd

      ## servers / infra
      nginx
      caddy
      sqlite
      acme-sh
      frp

      ## network basics
      dnsutils
      ipcalc

      ## networking tools
      pv
      nexttrace
      bandwhich
      webdav

      ## git / forge
      git-filter-repo
      gh
      tea

      ## core languages
      go
      python3
      nodejs # provides node, npm
      lua
      uv # replace for pip

      ## editor tooling
      ctags
      shellcheck

      ## nix
      nil # language server for Nix
      nixfmt-rs
      nix-output-monitor

      ## fish plugins
      fishPlugins.tide
      fishPlugins.sponge
      fishPlugins.autopair

      ## benchmarking
      hyperfine

      ## monitoring agent
      beszel

      ## disk / files
      ncdu
      tre-command

      ## misc
      xclip
      chase
      multitail
      sd # sed
      ouch
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      strace # a diagnostic, debugging and instructional userspace utility for Linux.
      ltrace # library call monitoring
      pahole
      iotop # io monitoring
      stun
      libtree
      fio
      ioping
      hdparm
      rldd
    ]
    ++ lib.optionals isDarwin [
      # xquartz
      ## This is automatically setup on Linux
      gettext
      gnused
    ];
}
