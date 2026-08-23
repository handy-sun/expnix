# This function creates a home-manager singlealone.
{
  nixpkgs,
  inputs,
  myvars,
  myutils,
  networkingVars,
}:

system:
{
  username ? "${myvars.user}",
  isWSL ? false,
  profileLevelOver ? { },
}:

let
  pkgs = import nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
    overlays = (import ../overlays/rldd.nix { inherit (nixpkgs) lib; }).nixpkgs.overlays;
  };
  profileLevel = myvars.profileLevel // profileLevelOver;
  ## Derived from the target platform instead of being passed in by callers.
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
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
inputs.home-manager.lib.homeManagerConfiguration {
  inherit
    pkgs
    extraSpecialArgs
    ;
  modules = [
    ../home
  ];
}
