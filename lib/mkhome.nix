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
  profileLevelOver ? { },
}:

let
  profileLevel = myvars.profileLevel // profileLevelOver;
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
      profileLevel
      ;
  };
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
    overlays = (import ../overlays/rldd.nix { inherit (nixpkgs) lib; }).nixpkgs.overlays;
  };
  inherit extraSpecialArgs;
  modules = [
    ../home
  ];
}
