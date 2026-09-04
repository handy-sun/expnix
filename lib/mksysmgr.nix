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
  pkgs = nixpkgs.legacyPackages.${system};
  profileLevel = myvars.profileLevel // profileLevelOver;
  ## Derived from the target platform (system-manager only targets Linux here).
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isHmSingle = true;
  homeDir = if "${username}" == "root" then "/root" else "/home/${username}";
  isHeLinux = !isDarwin && !isWSL;
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
      isLinux
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
    ./nix-common.nix
    inputs.home-manager.nixosModules.home-manager
    (
      { pkgs, ... }:
      {
        nixpkgs.hostPlatform = system;

        ## system-manager's bundled nixpkgs nix.nix defaults nix.enable to
        ## mkDefault false (Nix is preinstalled on managed hosts). Setting a plain
        ## value here wins over that and over the mkDefault in nix-common.nix,
        ## which would otherwise conflict at equal priority.
        nix.enable = true;

        system-manager = { inherit allowAnyDistro; };
        services.userborn.enable = true;

        programs.bash.completion.enable = true;
        users.defaultUserShell = pkgs.bash;

        users.users.${username} = {
          isNormalUser = true;
          group = myvars.group;
          home = homeDir;
          createHome = true;
          shell = pkgs.bash;
          openssh.authorizedKeys.keys = networkingVars.userAuthorizedKeysFor hostName;
          # system-manager does not provide NixOS's programs.fish module.
          ignoreShellProgramCheck = false;
          extraGroups = [
            "adm"
            "wheel"
          ];
        };

        security.sudo = {
          enable = true;
          wheelNeedsPassword = false;
        };

        environment.etc."ssh/ssh_known_hosts".text = networkingVars.ssh.knownHostsText;

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
    "modules/_system-manager"
    "hosts/${hostName}/system-manager.nix"
  ];
}
