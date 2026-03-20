# This function creates a NixOS/Darwin system based on our setup for a particular system(architecture).
{ nixpkgs, inputs, myvars }:

system: {
  username ? "${myvars.user}",
  isDarwin ? false,
  isWSL ? false
}:

let
  homeDir = if "${username}" == "root" then "/root" else if isDarwin then "/Users/${username}" else "/home/${username}";
  ## True if Linux, which is a heuristic for not being Darwin.
  isHeLinux = !isDarwin && !isWSL;
  extraSpecialArgs = { inherit inputs username myvars homeDir isDarwin isWSL isHeLinux; };
in inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.${system};
  inherit extraSpecialArgs;
  modules = [ ../home ];
}
