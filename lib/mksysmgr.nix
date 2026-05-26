# This function creates a system-manager configuration for non-NixOS Linux hosts.
{
  nixpkgs,
  inputs,
  myvars,
  myutils,
  networkingVars,
}:

hostName:
{
  system,
  username ? "${myvars.user}",
  isWSL ? false,
  profileLevelOver ? { },
  allowAnyDistro ? false,
}:

let
  profileLevel = myvars.profileLevel // profileLevelOver;
  isDarwin = false;
  isHmSingle = true;
  homeDir = if "${username}" == "root" then "/root" else "/home/${username}";
  isHeLinux = !isWSL;
  specialArgs = {
    inherit
      inputs
      hostName
      username
      myvars
      myutils
      networkingVars
      homeDir
      isDarwin
      isWSL
      isHeLinux
      isHmSingle
      profileLevel
      ;
  };
in
inputs.system-manager.lib.makeSystemConfig {
  inherit specialArgs;

  overlays = (import ../overlays/rldd.nix { inherit (nixpkgs) lib; }).nixpkgs.overlays;

  modules = [
    inputs.home-manager.nixosModules.home-manager
    (
      { pkgs, ... }:
      {
        nixpkgs.hostPlatform = system;
        nixpkgs.config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };

        system-manager = { inherit allowAnyDistro; };
        services.userborn.enable = true;
        nix = {
          enable = true;
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
            accept-flake-config = true;
            sandbox = false;
            filter-syscalls = false;
          };
        };

        users.groups.${username} = { };
        users.users.${username} = {
          isNormalUser = true;
          group = "users";
          home = homeDir;
          createHome = true;
          shell = pkgs.fish;
          # system-manager does not provide NixOS's programs.fish module.
          ignoreShellProgramCheck = true;
        };

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username} = import ../home;
          extraSpecialArgs = specialArgs;
          sharedModules = [ { targets.genericLinux.enable = true; } ];
        };
      }
    )
  ]
  ++ builtins.map myutils.relativeToRoot [
    "modules/networking/system-manager.nix"
    "modules/_system-manager"
    "hosts/${hostName}/system-manager.nix"
  ];
}
