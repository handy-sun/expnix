{
  pkgs,
  config,
  inputs,
  hostName,
  myutils,
  ...
}:
let
  reverseFilter = "~^(?!.*(kooya|流量|套餐|重置)).*$";
  template = pkgs.writeText "real-dns-nosniff.json" (
    builtins.readFile (inputs.sbtpl + "/substore/real-dns-nosniff.json")
  );
  inherit (pkgs.stdenv.hostPlatform) system;
  daeSopsFile = myutils.relativeToRoot "secrets/hosts/${hostName}/config.dae";
  subsSopsFile = myutils.relativeToRoot "secrets/sb-subs.yaml";
  mihomoSubsSopsFile = myutils.relativeToRoot "secrets/mhm-subs.yaml";
in
{
  disabledModules = [ "services/networking/sing-box.nix" ];
  imports = [
    (myutils.relativeToRoot "modules/mihomo")
    (myutils.relativeToRoot "modules/sing-box")
  ];

  sops.secrets.subs-main = {
    sopsFile = subsSopsFile;
    format = "yaml";
    key = "main";
    restartUnits = [ "sing-box.service" ];
  };

  sops.secrets.mihomo-subscription-url = {
    sopsFile = mihomoSubsSopsFile;
    format = "yaml";
    key = "main";
    restartUnits = [ "mihomo.service" ];
  };

  ## Render the config into /var/lib/dae instead of the volatile /run/secrets:
  ## dae caches `-file` subscriptions in `persist.d/` next to the config file
  ## (hardcoded, see common/subscription/subscription.go), so the config must
  ## live on persistent storage or every boot re-fetches subscriptions before
  ## the proxy is up. sops-install-secrets creates the parent dir itself.
  sops.secrets.dae-config = {
    path = "/var/lib/dae/config.dae";
    sopsFile = daeSopsFile;
    format = "binary";
    restartUnits = [ "dae.service" ];
  };

  services = {
    zerotierone.enable = true;

    sunshine = {
      enable = true;
      openFirewall = true;
      capSysAdmin = true; # required for KMS/DRM screen capture on Wayland (niri)
    };

    dae = {
      enable = true;
      package = inputs.daeuniverse.packages.${system}.dae-unstable;
      configFile = config.sops.secrets.dae-config.path;
    };

    sing-box = {
      enable = true;
      configGeneration = {
        enable = true;
        sourceUrlFile = config.sops.secrets.subs-main.path;
        policyFilter = "@🌐Proxy@⚡UrlTest-${reverseFilter}@💬AI@🚀LowLatency@🎮Steam";
        extraArgs = [
          "--template"
          "${template}"
          "--icmp"
        ];
      };
    };

    mihomo = {
      enable = true;
      subscriptionUrlFile = config.sops.secrets.mihomo-subscription-url.path;
      tunMode = true;
    };
  };

  ## systemd enforces this mode on every start, so the persisted config and
  ## the `persist.d/` subscription cache stay root-only even though the
  ## cached `.sub` files themselves are world-readable (0644).
  systemd.services.dae.serviceConfig = {
    StateDirectory = "dae";
    StateDirectoryMode = "0700";
  };
}
