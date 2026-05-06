# This function creates a NixOS/Darwin system based on our setup for a particular system(architecture).
{
  nixpkgs,
  inputs,
  self,
  myvars,
  myutils,
}:

hostName:
{
  system,
  username ? "${myvars.user}",
  isDarwin ? false,
  isWSL ? false,
  profileLevel ? myvars.profileLevel,
}:

let
  isHmSingle = false;
  homeDir =
    if "${username}" == "root" then
      "/root"
    else if isDarwin then
      "/Users/${username}"
    else
      "/home/${username}";
  ## True if Linux, which is a heuristic for not being Darwin.
  isHeLinux = !isDarwin && !isWSL;
  ## Config repo short rev: clean tree uses shortRev, dirty tree uses dirtyShortRev.
  configRepoRev = self.shortRev or self.dirtyShortRev;

  ## NixOS vs nix-darwin functionst
  systemFunc = if isDarwin then inputs.nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager =
    if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
  ## Expose some extra arguments so that our modules can parameterize better based on these values.
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
systemFunc rec {
  inherit system specialArgs;
  modules = [
    ## Bring in WSL if this is a WSL build
    (if isWSL then inputs.nixos-wsl.nixosModules.wsl else { })
    (
      if !isDarwin then
        { lib, ... }:
        {
          system.nixos.tags = lib.mkOverride 99 [ "gitrev-${configRepoRev}" ];
        }
      else
        { config, ... }:
        {
          system.darwinLabel = "${config.system.darwinVersion}.gitrev-${configRepoRev}";
        }
    )
    ../machines/nix-core.nix
    ../hosts/${hostName}
    ({
      nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
    })
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = import ../home;
      home-manager.extraSpecialArgs = specialArgs;
      # home-manager.backupFileExtension = "hmbak";
    }
  ];
}
