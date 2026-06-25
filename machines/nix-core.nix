{
  lib,
  hostName,
  ...
}:
{
  imports = [ ../lib/nix-common.nix ];

  # NixOS-only top-level options (not available in system-manager).
  nix.gc = {
    automatic = lib.mkDefault true;
    options = "--delete-older-than 7d";
  };

  networking.hostName = hostName;
}
