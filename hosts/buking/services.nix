{
  pkgs,
  inputs,
  myutils,
  ...
}:
let
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
    # onedrive.enable = true;
    zerotierone.enable = true;

    ## Moonlight stream host. Enabling this also flips on hardware.uinput
    ## (creates the uinput group + udev rule) and installs sunshine's udev
    ## rules; it runs as a user-level systemd service, not root. The user
    ## still needs to be in the input/uinput groups to inject keyboard/mouse
    ## events -- see users.users extraGroups in default.nix.
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
        policyFilter = "@🌐Proxy@⚡UrlTest-~^(?!.*(aote|kooya|流量|到期|过滤|官网)).*$@💬AI-~^(?!.*(流量|到期|过滤|官网)).*$@🚀LowLatency-~^(?!.*(流量|到期|过滤|官网)).*$";
        extraArgs = [
          "--template"
          "${template}"
          "--icmp"
        ];
      };
    };
  };
}
