{
  pkgs,
  lib,
  username,
  hostName,
  ...
}:
{
  nix = {
    # Determinate uses its own daemon to manage the Nix installation that
    # conflicts with nix-darwin's native Nix management.
    #
    # DONE: set this to false if you're using Determinate Nix.
    # NOTE: Turning off this option will invalidate all of the following nix configurations, 
    # and you will need to manually modify /etc/nix/nix.custom.conf to add the corresponding parameters.
    enable = lib.mkDefault true;

    package = pkgs.nix;

    settings = {
      trusted-users = [ username ];

      # enable flakes globally
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # substituers that will be considered before the official ones(https://cache.nixos.org)
      substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
      extra-substituters = [
        "https://nix-community.cachix.org"
      ];
      ## will be appended to the system-level trusted-public-keys
      extra-trusted-public-keys = [
        ## nix community's cache server public key
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      ## https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf
      auto-optimise-store = lib.mkDefault true;

      builders-use-substitutes = true;
    };

    # do garbage collection to keep disk usage low
    gc = {
      automatic = lib.mkDefault true;
      ## The option `nix.gc.dates` can no longer be used since it's been removed. Use `nix.gc.interval` instead.
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config = {
    allowUnfree = true; # allow non-FOSS pkgs
    allowUnsupportedSystem = true;
  };

  networking.hostName = hostName;
}
