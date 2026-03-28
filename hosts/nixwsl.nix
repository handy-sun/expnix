{
  lib,
  pkgs,
  config,
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

  systemd.services."sing-box".serviceConfig = if config.services.sing-box.enable then {
    ExecStart =  lib.mkForce [
      ""
      "${pkgs.sing-box}/bin/sing-box run -c /etc/sing-box/config.json -D /var/lib/sing-box"
    ];
    # StateDirectory = "sing-box";
  } else {};
}
