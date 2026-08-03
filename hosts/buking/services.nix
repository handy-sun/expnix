{
  pkgs,
  config,
  inputs,
  myutils,
  ...
}:
let
  reverseFilter = "~^(?!.*(kooya|流量|套餐|重置)).*$";
  template = pkgs.writeText "real-dns.json" (
    builtins.readFile (inputs.sbtpl + "/substore/real-dns.json")
  );
  inherit (pkgs.stdenv.hostPlatform) system;
  subsSopsFile = myutils.relativeToRoot "secrets/subs.yaml";
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
