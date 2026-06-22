{
  config,
  lib,
  myutils,
  ...
}:
let
  hostSecrets = myutils.relativeToRoot "secrets/hosts/reinsvps";
in
{
  sops.secrets.beszel-agent-env = {
    sopsFile = hostSecrets + "/beszel-agent.env";
    format = "dotenv";
    key = "";
    restartUnits = [ "beszel-agent.service" ];
  };

  services.beszel = {
    ## Beszel Hub — monitoring dashboard (PocketBase)
    hub = {
      enable = true;
      host = "0.0.0.0";
      port = 8090;
      # dataDir = "/var/lib/beszel-hub"; # default
    };

    agent = {
      enable = true;
      openFirewall = true;
      environmentFile = config.sops.secrets.beszel-agent-env.path;
    };
  };

  ## upstream module runs "beszel-hub history-sync" in ExecStartPre,
  ## but the command was removed in beszel 0.18.x — override to skip it
  systemd.services.beszel-hub.serviceConfig.ExecStartPre = lib.mkForce [
    "${config.services.beszel.hub.package}/bin/beszel-hub migrate up"
  ];
}
