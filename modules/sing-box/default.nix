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
  subscriptionFile = genCfg.configDir + "/subscription.txt";
  subscriptionUrlCredential = "sing-box-subscription-url";
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
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Subscription source URL for sbtpl base.js";
      };
      sourceUrlFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to a file containing the subscription source URL.";
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
    assertions = [
      {
        assertion = !genCfg.enable || (genCfg.sourceUrl != null) != (genCfg.sourceUrlFile != null);
        message = "Exactly one of services.sing-box.configGeneration.sourceUrl or sourceUrlFile must be set.";
      }
    ];

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
          sourceSetup =
            if genCfg.sourceUrlFile != null then
              ''
                credential_file="''${CREDENTIALS_DIRECTORY}/${subscriptionUrlCredential}"
                subscription_url="$(<"$credential_file")"
                case "$subscription_url" in
                  http://*|https://*) ;;
                  *)
                    echo "sing-box subscription URL must use http or https" >&2
                    exit 1
                    ;;
                esac
                trap 'rm -f ${lib.escapeShellArg subscriptionFile}' EXIT
                ${lib.getExe pkgs.wget} \
                  --quiet \
                  --timeout 15 \
                  --tries 3 \
                  --output-document ${lib.escapeShellArg subscriptionFile} \
                  --input-file "$credential_file"
                source_args=(--subscription-file ${lib.escapeShellArg subscriptionFile})
              ''
            else
              ''
                source_args=(--subscribe-link ${lib.escapeShellArg genCfg.sourceUrl})
              '';
          script = pkgs.writeShellScript "sing-box-pregen" ''
            set -euo pipefail
            umask 077
            test -d ${lib.escapeShellArg genCfg.configDir} || mkdir -p ${lib.escapeShellArg genCfg.configDir}
            test -h ${lib.escapeShellArg configFile} && rm ${lib.escapeShellArg configFile}
            ${sourceSetup}
            ${lib.getExe pkgs.nodejs} ${inputs.sbtpl}/node/base.js \
              "''${source_args[@]}" \
              --policy-filter ${lib.escapeShellArg genCfg.policyFilter} \
              --output-file ${lib.escapeShellArg configFile} \
              ${extraArgsStr}
            ${lib.getExe cfg.package} check --config ${lib.escapeShellArg configFile}
            chown --reference=${lib.escapeShellArg genCfg.configDir} ${lib.escapeShellArg configFile}
          '';
        in
        {
          ExecStartPre = "${script}";
          TimeoutStartSec = "60s";
          ExecStart = [
            ""
            "${lib.getExe cfg.package} -D ${"$"}{STATE_DIRECTORY} -C ${"$"}{RUNTIME_DIRECTORY} run"
          ];
          Restart = "on-failure";
          RestartSec = "10s";
          StartLimitBurst = 3;
        }
        // lib.optionalAttrs (genCfg.sourceUrlFile != null) {
          LoadCredential = [ "${subscriptionUrlCredential}:${genCfg.sourceUrlFile}" ];
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
