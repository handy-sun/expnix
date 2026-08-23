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

        system-manager = { inherit allowAnyDistro; };
        services.userborn.enable = true;

        users.users.${username} = {
          isNormalUser = true;
          group = myvars.group;
          home = homeDir;
          createHome = true;
          shell = pkgs.fish;
          openssh.authorizedKeys.keys = networkingVars.userAuthorizedKeysFor hostName;
          # system-manager does not provide NixOS's programs.fish module.
          ignoreShellProgramCheck = true;
          extraGroups = [
            "adm"
            "wheel"
          ];
        };

        security.sudo = {
          enable = true;
          wheelNeedsPassword = false;
        };

        # environment.etc."hosts" = {
        #   text = ''
        #     127.0.0.1 localhost
        #     ::1 localhost ip6-localhost ip6-loopback
        #     127.0.1.1 ${hostName}

        #     # The following lines are desirable for IPv6 capable hosts
        #     ::1     ip6-localhost ip6-loopback
        #     fe00::0 ip6-localnet
        #     ff00::0 ip6-mcastprefix
        #     ff02::1 ip6-allnodes
        #     ff02::2 ip6-allrouters

        #     ## expnix managed hosts
        #     ${networkingVars.hostsText}
        #   '';
        #   replaceExisting = true;
        # };

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
