{
  lib,
  pkgs,
  config,
  myutils,
  ...
}:
{
  imports = (lib.map myutils.relativeToRoot [
    "machines/wsl-base.nix"
    "nixos"
  ]);

  ## warning: not applying GID change of group ‘docker’ (997 -> 131) in /etc/group
  users.groups.docker.gid = lib.mkForce 997;

  systemd.services."sing-box".serviceConfig = if config.services.sing-box.enable then {
    ExecStart =  lib.mkForce [
      ""
      "${pkgs.sing-box}/bin/sing-box run -c /etc/sing-box/config.json -D /var/lib/sing-box"
    ];
    # StateDirectory = "sing-box";
  } else {};

  services.beszel.agent = {
    enable = true;
    environmentFile = "/etc/beszel-agent.env";
    openFirewall = true;
  };
}
