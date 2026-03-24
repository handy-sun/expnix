{ lib, hostName, ... }:

{
  imports = [
    ../machines/nix-core.nix
    ../machines/wsl-base.nix
    ../nixos/pkgenv.nix
    ../nixos/services.nix
  ];

  # networking.hostName = lib.mkForce hostName;
}
