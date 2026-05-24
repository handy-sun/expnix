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

  ## Mask mounts that are not available in isolated OrbStack containers
  systemd.units."sys-kernel-debug.mount".enable = false;
}
