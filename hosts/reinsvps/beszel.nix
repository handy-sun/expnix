{
  config,
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
      host = "127.0.0.1";
      port = 8090;
      # dataDir = "/var/lib/beszel-hub"; # default
    };

    agent = {
      enable = true;
      openFirewall = true;
      environmentFile = config.sops.secrets.beszel-agent-env.path;
    };
  };
}
