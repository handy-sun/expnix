{
  pkgs,
  lib,
  username,
  myutils,
  homeDir,
  ...
}:
let
  beszelAgentEnv = homeDir + "/.config/beszel/beszel-agent.env";
in
{
  imports = (
    lib.map myutils.relativeToRoot [
      "machines/darwin-base.nix"
      "overlays/darwin-lld.nix"
      "modules/caddy-webdav"
      "modules/sing-box/darwin.nix"
    ]
  );

  services.tailscale = {
    enable = true;
    overrideLocalDns = false;
  };

  launchd.user.agents.beszel-agent = {
    script = ''
      #!/usr/bin/env bash
      set -a
      test -f ${beszelAgentEnv} && source ${beszelAgentEnv}
      set +a
      exec ${pkgs.beszel}/bin/beszel-agent "$@"
    '';
    serviceConfig = {
      Label = "nixdwn.${username}.beszel-agent";
      LimitLoadToHosts = [
        "Aqua"
        "Background"
        "LoginWindow"
        "StandardIO"
        "System"
      ];
      ProcessType = "Background";
      KeepAlive = true;
      RunAtLoad = true;
      ThrottleInterval = 5;
      StandardErrorPath = "/tmp/beszel-agent.log";
      StandardOutPath = "/tmp/beszel-agent.log";
    };
  };
}
