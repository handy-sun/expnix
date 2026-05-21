{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.beszel.agent;
in
{
  options.services.beszel.agent = {
    enable = lib.mkEnableOption "Beszel server monitoring agent";
    package = lib.mkPackageOption pkgs "beszel" { };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        SKIP_SYSTEMD = "true";
      };
      description = ''
        Public environment variables for beszel-agent. Keep secrets such as KEY
        in environmentFile instead.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "/etc/beszel-agent.env";
      description = ''
        Path to a systemd EnvironmentFile containing private beszel-agent
        settings such as KEY.
      '';
    };

    extraPath = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra packages to add to the beszel-agent PATH.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.beszel-agent = {
      description = "Beszel Server Monitoring Agent";
      wantedBy = [ "system-manager.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment = cfg.environment;
      path = cfg.extraPath;

      serviceConfig = {
        Type = "simple";
        ExecStart = lib.getExe' cfg.package "beszel-agent";
        DynamicUser = true;
        User = "beszel-agent";
        Restart = "on-failure";
        RestartSec = "30s";

        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = "read-only";
        ProtectSystem = "strict";
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [ "@system-service" ];
        UMask = 27;
      }
      // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };
    };
  };
}
