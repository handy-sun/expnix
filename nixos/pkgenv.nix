{ lib, pkgs, ... }:

{
  nixpkgs = {
    hostPlatform = lib.mkDefault "aarch64-linux";
    config.allowUnfree = true; # allow non-FOSS pkgs
  };
  networking.hostName = "expnix";
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      # dates = "Sun *-*-* 00:00:00";
      options = "--delete-older-than 7d";
    };
    settings = {
      trusted-users = [ "root" "qi" ];
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
    rsync
    dae
    glider
    sing-box
    zsh
    tmux
    docker
    docker-compose
    ctags
    zerotierone

    ## programming
    gcc
    go
    # cmake
    python3
    lua
    nodejs_25
    # nodejs-slim_25
    # perl

    ## rust related
    # cargo-bloat # find what takes the most space in the executable
    # cargo-cache # manage cargo cache (${CARGO_HOME}); print and remove dirs selectively
    # cargo-zigbuild
    rustup # provides rustfmt, cargo-clippy, rustup, cargo, rust-lldb, rust-analyzer, rustc, rust-gdb, cargo-fmt
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
    # timeZone = "Asia/Shanghai";
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
