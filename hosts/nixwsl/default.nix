{
  lib,
  pkgs,
  config,
  myutils,
  ...
}:
{
  imports = (
    lib.map myutils.relativeToRoot [
      "machines/wsl-base.nix"
      "nixos"
    ]
  );

  ## warning: not applying GID change of group ‘docker’ (997 -> 131) in /etc/group
  users.groups.docker.gid = lib.mkForce 997;

  services.sing-box.enable = lib.mkForce false;

  services.beszel.agent = {
    enable = true;
    environmentFile = "/etc/beszel-agent.env";
    openFirewall = true;
  };
}
