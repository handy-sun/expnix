{
  lib,
  ...
}:

let 
  scan = import ../../lib/scanpaths.nix { inherit lib; };
in
{
  imports = scan.scanPaths ./.;
}