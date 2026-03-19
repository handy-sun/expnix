# This function creates a NixOS/Darwin system based on our setup for a particular system(architecture).
{ nixpkgs, inputs, myvars }:

hostName: {
  system,
  username ? "${myvars.user}",
  isDarwin ? false,
  isWSL ? false
}:

let
  homeDir = if "${username}" == "root" then "/root" else if isDarwin then "/Users/${username}" else "/home/${username}";
  ## True if Linux, which is a heuristic for not being Darwin.
  isLinux = !isDarwin && !isWSL;

  ## NixOS vs nix-darwin functionst
  systemFunc = if isDarwin then inputs.nix-darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager = if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
  ## Expose some extra arguments so that our modules can parameterize better based on these values.
  specialArgs = { inherit inputs hostName username myvars homeDir isWSL isLinux; };
in systemFunc rec {
  inherit system specialArgs;
  modules = [
    ## Bring in WSL if this is a WSL build
    (if isWSL then inputs.nixos-wsl.nixosModules.wsl else {})
    ../machines/nix-core.nix
    ../hosts/${hostName}.nix
    home-manager.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${username} = import ../home;
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.backupFileExtension = "hmbak";
    }
  ];
}
