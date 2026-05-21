# This function creates a system-manager configuration for non-NixOS Linux hosts.
{
  nixpkgs,
  inputs,
  myvars,
  myutils,
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
  isHmSingle = false;
  homeDir = if "${username}" == "root" then "/root" else "/home/${username}";
  isHeLinux = !isWSL;
  specialArgs = {
    inherit
      inputs
      hostName
      username
      myvars
      myutils
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
        nix.enable = true;
        services.userborn.enable = true;

        users.groups.${username} = { };
        users.users.${username} = {
          isNormalUser = true;
          group = username;
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
        };
      }
    )
  ]
  ++ builtins.map myutils.relativeToRoot [
    "modules/_system-manager"
    "hosts/${hostName}/system-manager.nix"
  ];
}
