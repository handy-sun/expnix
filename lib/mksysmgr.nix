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
  ## Shared vars plus the resolved target platform, exposed to modules as `myvars`.
  hostVars = myvars // {
    archSystem = pkgs.stdenv.hostPlatform.system;
  };
  isHmSingle = true;
  homeDir = if "${username}" == "root" then "/root" else "/home/${username}";
  isHeLinux = !isDarwin && !isWSL;
  specialArgs = {
    myvars = hostVars;
    inherit
      inputs
      hostName
      username
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

  overlays =
    (import ../overlays/rldd.nix { inherit (nixpkgs) lib; }).nixpkgs.overlays
    ++ (import ../overlays/netwatch.nix { }).nixpkgs.overlays
    ++ (import ../overlays/rustdesk.nix { }).nixpkgs.overlays
    ++ (import ../overlays/beszel.nix { }).nixpkgs.overlays;

  modules = [
    ./nix-common.nix
    inputs.home-manager.nixosModules.home-manager
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
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

        ## pam_env (Linux-PAM >= 1.7) also reads /etc/environment.d, but unlike
        ## systemd's environment-d generator it does not expand ${...}. Upstream
        ## writes ${USER}/${PATH}/${XDG_DATA_DIRS} verbatim, so every PAM session
        ## (sshd, sudo, su) keeps those literals inside PATH and loses the real
        ## base PATH. Mirror upstream's file with everything expanded; the
        ## variables block stays generated from environment.variables, so session
        ## variables added elsewhere are still honoured.
        environment.etc."environment.d/10-system-manager.conf" = lib.mkForce {
          text = ''
            ${lib.concatLines (lib.mapAttrsToList (k: v: ''${k}="${v}"'') config.environment.variables)}
            PATH=/etc/profiles/per-user/${username}/bin:/run/system-manager/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
            XDG_DATA_DIRS=/etc/profiles/per-user/${username}/share:/run/system-manager/sw/share:/usr/local/share:/usr/share
            NIX_USER_PROFILE_DIR=/nix/var/nix/profiles/per-user/${username}
            NIX_PROFILES="/run/system-manager/sw /nix/var/nix/profiles/default /etc/profiles/per-user/${username} ${homeDir}/.local/state/nix/profile ${homeDir}/.nix-profile"
          '';
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
    "modules/_system-manager"
    "hosts/${hostName}/system-manager.nix"
  ];
}
