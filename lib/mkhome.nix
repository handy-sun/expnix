# This function creates a home-manager singlealone.
{
  nixpkgs,
  inputs,
  myvars,
  myutils,
}:

system:
{
  username ? "${myvars.user}",
  isDarwin ? false,
  isWSL ? false,
}:

let
  isHmSingle = true;
  homeDir =
    if "${username}" == "root" then
      "/root"
    else if isDarwin then
      "/Users/${username}"
    else
      "/home/${username}";
  ## True if Linux, which is a heuristic for not being Darwin.
  isHeLinux = !isDarwin && !isWSL;
  extraSpecialArgs = {
    inherit
      inputs
      username
      myvars
      myutils
      homeDir
      isDarwin
      isWSL
      isHeLinux
      isHmSingle
      ;
  };
in
inputs.home-manager.lib.homeManagerConfiguration {
  # pkgs = import nixpkgs {
  #   inherit system;
  #   config = {
  #     allowUnfree = true;
  #     allowUnsupportedSystem = true;
  #   };
  #   overlays = [ inputs.rust-overlay.overlays.default ];
  # };

  # pkgs = nixpkgs.legacyPackages.${system}.extend inputs.rust-overlay.overlays.default;

  pkgs = nixpkgs.legacyPackages.${system};
  inherit extraSpecialArgs;
  modules = [
    ../home
  ];
}
