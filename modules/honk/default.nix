{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.honk-core;
  # honk resolves geoip.dat/geosite.dat from $DAE_LOCATION_ASSET first; keep them in the store.
  geoAssets = pkgs.linkFarm "honk-geo-assets" [
    {
      name = "geosite.dat";
      path = "${pkgs.v2ray-domain-list-community}/share/v2ray/geosite.dat";
    }
    {
      name = "geoip.dat";
      path = "${pkgs.v2ray-geoip}/share/v2ray/geoip.dat";
    }
  ];
in
{
  options.services.honk-core = {
    enable = lib.mkEnableOption "honk transparent proxy engine";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "honk-core package to use.";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/honk/config.dae";
      description = "Path to the honk (.dae dialect) config file.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.honk-core = {
      description = "honk transparent proxy engine";
      documentation = [ "https://github.com/daeuniverse/honk" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      # dae and honk attach eBPF to the same TC/dae0 datapath; never run both.
      conflicts = [ "dae.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "notify";
        ExecStart = "${lib.getExe cfg.package} --disable-timestamp --config ${lib.escapeShellArg cfg.configFile}";
        ExecReload = "${lib.getExe cfg.package} reload";
        WorkingDirectory = "/var/lib/honk";
        StateDirectory = "honk";
        Restart = "on-failure";
        RestartSec = "2s";
        TimeoutStopSec = "30s";
        LimitNOFILE = 1048576;
        LimitMEMLOCK = "infinity";
        UMask = "0077";
      };
      environment = {
        DAE_LOCATION_ASSET = geoAssets;
      };
    };
  };
}
