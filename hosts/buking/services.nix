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
  template = pkgs.writeText "real-dns.json" (
    builtins.readFile (inputs.sbtpl + "/substore/real-dns.json")
  );
  inherit (pkgs.stdenv.hostPlatform) system;
  daeSopsFile = myutils.relativeToRoot "secrets/hosts/${hostName}/config.dae";
  subsSopsFile = myutils.relativeToRoot "secrets/sb-subs.yaml";
in
{
  disabledModules = [ "services/networking/sing-box.nix" ];
  imports = [ (myutils.relativeToRoot "modules/sing-box") ];

  sops.secrets.subs-main = {
    sopsFile = subsSopsFile;
    format = "yaml";
    key = "main";
    restartUnits = [ "sing-box.service" ];
  };

  sops.secrets.dae-config = {
    path = "/run/secrets/dae-config.dae";
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
  };
}
