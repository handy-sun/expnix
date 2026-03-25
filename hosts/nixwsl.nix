{
  lib,
  ...
}:
{
  imports = [
    ../machines/nix-core.nix
    ../machines/wsl-base.nix
    ../nixos/pkgenv.nix
    ../nixos/services.nix
  ];

  ## warning: not applying GID change of group ‘docker’ (997 -> 131) in /etc/group
  users.groups.docker.gid = lib.mkForce 997;
}