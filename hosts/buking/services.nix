{
  pkgs,
  inputs,
  myutils,
  ...
}:
let
  reverseFilter = "~^(?!.*(kooya)).*$";
  template = pkgs.writeText "real-dns.json" (
    builtins.readFile (inputs.sbtpl + "/substore/real-dns.json")
  );
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  disabledModules = [ "services/networking/sing-box.nix" ];
  imports = [ (myutils.relativeToRoot "modules/sing-box") ];

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
        sourceUrl = "http://handyMini:3001/c53248f264d9997/download/collection/main?target=V2Ray";
        policyFilter = "@🌐Proxy@⚡UrlTest-${reverseFilter}@💬AI@🚀LowLatency";
        extraArgs = [
          "--template"
          "${template}"
          "--icmp"
        ];
      };
    };
  };
}
