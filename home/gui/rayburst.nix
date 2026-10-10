{
  lib,
  pkgs,
  myutils,
  profileLevel,
  isLinux,
  inputs,
  ...
}:

let
  rayburst = pkgs.callPackage (myutils.relativeToRoot "packages/rayburst.nix") {
    inherit inputs;
  };
in
lib.mkIf (profileLevel.guiBase && isLinux) {
  home.packages = [ rayburst ];
}
