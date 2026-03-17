{ lib, hostName, ... }:

{
  imports = [
    ../machines/orb-base.nix
    ../nixos/pkgenv.nix
    ../nixos/services.nix
  ];

  networking.hostName = lib.mkForce hostName;
}