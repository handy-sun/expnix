{ lib, hostName, ... }:

{
  imports = [
    ../machines/wsl-base.nix
    ../nixos/pkgenv.nix
    ../nixos/services.nix
  ];

  networking.hostName = lib.mkForce hostName;
}
