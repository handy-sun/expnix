# This function creates a NixOS/Darwin system based on our setup for a particular system(architecture).
{ nixpkgs, inputs, myvars }:

hostName: {
  system, # architecture
  user ? "${myvars.user}",
  isDarwin ? false,
  isWSL ? false
}:

let
  ## True if Linux, which is a heuristic for not being Darwin.
  isLinux = !isDarwin && !isWSL;

  ## NixOS vs nix-darwin functionst
  systemFunc = if isDarwin then inputs.darwin.lib.darwinSystem else nixpkgs.lib.nixosSystem;
  home-manager = if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
  ## Expose some extra arguments so that our modules can parameterize better based on these values.
  specialArgs = { inherit inputs hostName myvars isWSL isLinux; };
in systemFunc rec {
  inherit system specialArgs;
  modules = [
    ../machines/nix-core.nix
    ../hosts/${hostName}.nix
    home-manager.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.${user} = import ../home;
      home-manager.extraSpecialArgs = specialArgs;
    }
  ];
}