{
  # pkgs,
  lib,
  myutils,
  ...
}:

{
  imports = (
    lib.map myutils.relativeToRoot [
      "machines/orb-base.nix"
      "nixos"
      "overlays/deno.nix"
    ]
  );

  ## To use some network tools.
  services.resolved.enable = lib.mkForce true;
  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 223.5.5.5
    nameserver 114.114.114.114
    options edns0
    search .
  '';

  services.dae.enable = lib.mkForce false;
}
