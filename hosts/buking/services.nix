{
  pkgs,
  config,
  inputs,
  myutils,
  ...
}:
let
  reverseFilter = "~^(?!.*(kooya|流量|套餐|重置)).*$";
  storePathConfig = inputs.sbtpl + "/substore/real-dns-nosniff.json";
  # storePathConfig = pkgs.writeText "real-dns-nosniff.json" (
  #   builtins.readFile (inputs.sbtpl + "/substore/real-dns-nosniff.json")
  # );
  inherit (pkgs.stdenv.hostPlatform) system;
  subsSopsFile = myutils.relativeToRoot "secrets/sb-subs.yaml";
  mihomoSubsSopsFile = myutils.relativeToRoot "secrets/mhm-subs.yaml";
in
{
  disabledModules = [ "services/networking/sing-box.nix" ];
  imports = [
    (myutils.relativeToRoot "modules/mihomo")
    (myutils.relativeToRoot "modules/sing-box")
  ];

  sops.secrets = {
    subs-main = {
      sopsFile = subsSopsFile;
      format = "yaml";
      key = "main";
      restartUnits = [ "sing-box.service" ];
    };

    mihomo-subscription-url = {
      sopsFile = mihomoSubsSopsFile;
      format = "yaml";
      key = "main";
      restartUnits = [ "mihomo.service" ];
    };
  };

  environment.etc."dae/config.dae" = {
    source = inputs.my-dotfiles + "/dae/config-with-singb.dae";
    mode = "0600";
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
      configFile = "/etc/dae/config.dae";
    };

    sing-box = {
      enable = true;
      configGeneration = {
        enable = true;
        sourceUrlFile = config.sops.secrets.subs-main.path;
        policyFilter = "@🌐Proxy@⚡UrlTest-${reverseFilter}@💬AI@🚀LowLatency@🎮Steam";
        extraArgs = [
          "--template"
          "${storePathConfig}"
          "--icmp"
        ];
      };
    };

    mihomo = {
      enable = false;
      subscriptionUrlFile = config.sops.secrets.mihomo-subscription-url.path;
      tunMode = true;
    };
  };

  systemd.services.dae = {
    ## dae's only node is sing-box's mixed inbound (127.0.0.1:2334). Never start it before sing-box is listening: sing-box's ExecStartPre fetches
    ## the subscription and generates config first, which used to make dae's health checks hit a dead port at boot.
    after = [ "sing-box.service" ];
    wants = [ "sing-box.service" ];
  };
}
