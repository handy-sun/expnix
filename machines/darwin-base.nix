{ pkgs, hostname, username, lib, ... }:

{
  ###################################################################################
  #
  #  macOS's System configuration
  #
  #  All the configuration options are documented here:
  #    https://daiderd.com/nix-darwin/manual/index.html#sec-options
  #
  ###################################################################################
  system = {
    stateVersion = 6;

    defaults = {
      ## COMMAND: defaults read com.apple.menuextra.clock (ShowAMPM = 1; ## means: menuExtraClock.Show24Hour = false;)
      ## default: null
      menuExtraClock.Show24Hour = true;  # show 24 hour clock
    };
  };
  ## Add ability to used TouchID for sudo authentication
  # security.pam.services.sudo_local.touchIdAuth = true;

  ## Create /etc/zshrc that loads the nix-darwin environment.
  ## this is required if you want to use darwin's default shell - zsh
  programs.zsh.enable = true;

  ## Set this to false because i am using Determinate Nix.
  nix.enable = lib.mkForce false;
  nix.gc.automatic = lib.mkForce false;

  # Disable auto-optimise-store because of this issue:
  #   https://github.com/NixOS/nix/issues/7273
  # "error: cannot link '/nix/store/.tmp-link-xxxxx-xxxxx' to '/nix/store/.links/xxxx': File exists"
  nix.settings.auto-optimise-store = false;

  #############################################################
  #
  #  Host & Users configuration
  #
  #############################################################
  ## COMMAND: scutil --get HostName (HostName: not set)
  networking.hostName = hostname;
  ## COMMAND: scutil --get ComputerName
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;

  users.users."${username}"= {
    home = "/Users/${username}";
    description = username;
  };
  system.primaryUser = username;

  nix.settings.trusted-users = [ username ];

  ##########################################################################
  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  ##########################################################################
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  # DONE To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = false;

    onActivation = {
      autoUpdate = false;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      # cleanup = "zap";
    };

    taps = [
      "homebrew/services"
    ];

    # `brew install`
    # DONE Feel free to add your favorite apps here.
    brews = [
      # "aria2"  # download tool
    ];

    # `brew install --cask`
    # DONE Feel free to add your favorite apps here.
    casks = [
      # "google-chrome"
    ];
  };
}
