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

    ## Moonlight stream host. Enabling this also flips on hardware.uinput
    ## (creates the uinput group + udev rule) and installs sunshine's udev
    ## rules; it runs as a user-level systemd service, not root. The user
    ## still needs to be in the input/uinput groups to inject keyboard/mouse
    ## events -- see users.users extraGroups in default.nix.
    sunshine = {
      enable = true;
      openFirewall = true;
      capSysAdmin = true; # required for KMS/DRM screen capture on Wayland (niri)
      package = pkgs.sunshine.override {
        cudaSupport = true;
        cudaPackages = pkgs.cudaPackages.overrideScope (_: _: { cuda_compat = null; });
      };
      settings.encoder = "nvenc";
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
