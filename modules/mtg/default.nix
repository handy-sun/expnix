{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mtg;
in
{
  options.services.mtg = {
    enable = lib.mkEnableOption "mtg Telegram MTProto proxy";

    package = lib.mkPackageOption pkgs "mtg" { };

    secret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Proxy secret (Base64 or hex format). Required when configFile is not set.";
    };

    bind = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0:443";
      description = "Address to bind the proxy to (host:port).";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to TOML config file. When set, runs `mtg run` instead of `simple-run`.";
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra CLI flags for `mtg simple-run` (only used when configFile is not set).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.configFile != null || cfg.secret != null;
        message = "services.mtg: either configFile or secret must be set";
      }
    ];

    systemd.services.mtg = {
      description = "mtg Telegram MTProto proxy";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig =
        let
          execStart =
            if cfg.configFile != null then
              "${lib.getExe cfg.package} run ${cfg.configFile}"
            else
              lib.escapeShellArgs (
                [
                  (lib.getExe cfg.package)
                  "simple-run"
                  cfg.bind
                  cfg.secret
                ]
                ++ cfg.extraFlags
              );
        in
        {
          Type = "simple";
          ExecStart = execStart;
          DynamicUser = true;
          Restart = "on-failure";
          RestartSec = "5s";
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
        };
    };
  };
}
