{ config, lib, pkgs, modulesPath, ... }:

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
    wget
    dae
    glider
    sing-box
    zsh
    tmux
    docker
    docker-compose
    ctags
    zerotierone
  ];

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
