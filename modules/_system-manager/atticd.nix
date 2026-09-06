{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.atticd;
  format = pkgs.formats.toml { };

  checkedConfigFile =
    pkgs.runCommand "checked-attic-server.toml"
      {
        configFile = format.generate "server.toml" cfg.settings;
      }
      ''
        export ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="$(${lib.getExe pkgs.openssl} genrsa -traditional 4096 | ${pkgs.coreutils}/bin/base64 -w0)"
        export ATTIC_SERVER_DATABASE_URL="sqlite://:memory:"
        ${lib.getExe cfg.package} --mode check-config -f "$configFile"
        cat <"$configFile" >"$out"
      '';

  atticadmWrapper = pkgs.writeShellScriptBin "atticd-atticadm" ''
    exec systemd-run \
      --quiet \
      --pipe \
      --wait \
      --collect \
      --service-type=exec \
      --property=EnvironmentFile=${cfg.environmentFile} \
      --property=DynamicUser=yes \
      --property=User=atticd \
      --working-directory / \
      -- \
      ${lib.getExe' cfg.package "atticadm"} -f ${checkedConfigFile} "$@"
  '';
in
{
  options.services.atticd = {
    enable = lib.mkEnableOption "the atticd Nix binary cache server";

    package = lib.mkPackageOption pkgs "attic-server" { };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Environment file containing ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64.";
    };

    mode = lib.mkOption {
      type = lib.types.enum [
        "monolithic"
        "api-server"
        "garbage-collector"
      ];
      default = "monolithic";
    };

    settings = lib.mkOption {
      type = format.type;
      default = { };
      description = "Structured atticd TOML configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.environmentFile != null;
        message = "services.atticd.environmentFile must point to an environment file containing ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64.";
      }
    ];

    services.atticd.settings = {
      chunking = lib.mkDefault {
        nar-size-threshold = 65536;
        min-size = 16384;
        avg-size = 65536;
        max-size = 262144;
      };
      database.url = lib.mkDefault "sqlite:///var/lib/atticd/server.db?mode=rwc";
      storage = lib.mkDefault {
        type = "local";
        path = "/var/lib/atticd/storage";
      };
    };

    environment.systemPackages = [ atticadmWrapper ];

    systemd.services.atticd = {
      description = "Attic binary cache server";
      wantedBy = [ "system-manager.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} -f ${checkedConfigFile} --mode ${cfg.mode}";
        EnvironmentFile = cfg.environmentFile;
        StateDirectory = "atticd";
        DynamicUser = true;
        User = "atticd";
        Group = "atticd";
        Restart = "on-failure";
        RestartSec = 10;
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = "";
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@resources"
          "~@privileged"
        ];
        UMask = "0077";
      };
    };
  };
}
