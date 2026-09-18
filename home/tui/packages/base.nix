## ============================================================
## tuibase — always included: essential terminal tools for SSH
## ============================================================
{
  pkgs,
  inputs,
  myvars,
  isDarwin,
  isLinux,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      less
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
      tree
      just
      pass
      util-linux

      ## archives (basics)
      gzip
      unzip
      zip
      bzip2

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
      speedtest-cli

      ## git / forge
      inputs.githand.packages.${myvars.archSystem}.default
      git-credential-manager
      git-filter-repo
      gh
      tea

      ## core languages
      python3
      uv # replace for pip
      nodejs # provides node, npm
      lua5_4

      ## editor tooling
      ctags
      shellcheck

      ## nix
      nil # language server for Nix
      nixfmt-rs
      nix-output-monitor
      system-manager

      ## benchmarking
      hyperfine

      ## monitoring agent
      beszel

      ## disk / files
      ncdu
      tre-command

      ## misc
      xclip
      multitail
      sd # sed
      ouch
      age
      sops
      ssh-to-age
      w3m-nographics
    ]
    ++ lib.optionals isLinux [
      strace # a diagnostic, debugging and instructional userspace utility for Linux.
      ltrace # library call monitoring
      pahole
      iotop # io monitoring
      stun
      libtree
      fio
      ioping
      hdparm
      exfatprogs
    ]
    ++ lib.optionals isDarwin [
      # xquartz
      ## This is automatically setup on Linux
      gettext
      gnused
    ];
}
