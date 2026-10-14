{
  lib,
  ...
}:
let
  daeConfig = "/etc/dae/config.dae";
  inherit (lib) mkDefault;

  settings = {
    max-concurrent-downloads = 10;
    max-concurrent-uploads = 10;
  };
in
{
  services = {
    # timesyncd.enable = true; # NTP
    journald.settings.Journal = {
      SystemMaxUse = "2G";
      RuntimeMaxUse = "200M";
    };

    iperf3 = {
      enable = mkDefault true;
      port = 5201;
      ## Omitting --bind makes iperf3 listen on all available interfaces.
      bind = null;
      openFirewall = true;
    };

    dae = {
      enable = mkDefault false;
      openFirewall = {
        enable = true;
        port = 12345;
      };
      configFile = mkDefault daeConfig;
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      extraSetFlags = [ "--accept-routes=true" ];
    };
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    daemon = { inherit settings; };
  };
}
