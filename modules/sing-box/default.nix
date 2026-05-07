{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.services.sing-box;

  defaultConfigDir = "/run/sing-box";

  genCfg = cfg.configGeneration;
  configFile = genCfg.configDir + "/config.json";
  extraArgsStr = lib.escapeShellArgs genCfg.extraArgs;
in
{
  options.services.sing-box = {
    enable = lib.mkEnableOption "sing-box universal proxy platform";
    package = lib.mkPackageOption pkgs "sing-box" { };

    configPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to static sing-box config file. Only used when configGeneration is disabled.";
    };

    configGeneration = {
      enable = lib.mkEnableOption "pre-start config generation via sbtpl";
      sourceUrl = lib.mkOption {
        type = lib.types.str;
        description = "Subscription source URL for sbtpl base.js";
      };
      policyFilter = lib.mkOption {
        type = lib.types.str;
        description = "Policy filter expression passed to base.js -p";
      };
      configDir = lib.mkOption {
        type = lib.types.str;
        default = defaultConfigDir;
        description = "Output directory for the generated config.json";
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to base.js";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    services.dbus.packages = [ cfg.package ];
    systemd.packages = [ cfg.package ];

    systemd.services.sing-box = {
      serviceConfig = {
        User = "sing-box";
        Group = "sing-box";
        StateDirectory = "sing-box";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "sing-box";
        RuntimeDirectoryMode = "0700";
      }
      // lib.optionalAttrs genCfg.enable (
        let
          script = pkgs.writeShellScript "sing-box-pregen" ''
            test -d ${genCfg.configDir} || mkdir -p ${genCfg.configDir}
            test -h ${configFile} && rm ${configFile}
            ${lib.getExe pkgs.nodejs} ${inputs.sbtpl}/node/base.js \
              -s '${genCfg.sourceUrl}' \
              -p '${genCfg.policyFilter}' \
              -o ${configFile} \
              ${extraArgsStr}
            chown --reference=${genCfg.configDir} ${configFile}
          '';
        in
        {
          ExecStartPre = "${script}";
          ExecStartPreTimeoutSec = "20s";
          ExecStart = [
            ""
            "${lib.getExe cfg.package} -D ${"$"}{STATE_DIRECTORY} -C ${"$"}{RUNTIME_DIRECTORY} run"
          ];
          Restart = "on-failure";
          RestartSec = "10s";
          StartLimitBurst = 3;
        }
      );
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    users = {
      users.sing-box = {
        isSystemUser = true;
        group = "sing-box";
        home = "/var/lib/sing-box";
      };
      groups.sing-box = { };
    };
  };
}
