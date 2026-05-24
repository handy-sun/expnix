{
  pkgs,
  lib,
  username,
  hostName,
  ...
}:
{
  nix = {
    enable = lib.mkDefault true; # NOTE: if you're using Determinate Nix ,turning off this option
    package = pkgs.nix;
    settings = {
      trusted-users = [ username ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.garnix.io"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        # "https://mirror.sjtu.edu.cn/nix-channels/store"
      ];
      trusted-public-keys = [
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
      extra-substituters = [
        "https://cache.numtide.com"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      auto-optimise-store = lib.mkDefault true;
      builders-use-substitutes = true;
      accept-flake-config = true;
    };
    gc = {
      automatic = lib.mkDefault true;
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
  };

  networking.hostName = hostName;
}
