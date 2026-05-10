{
  config,
  lib,
  pkgs,
  inputs,
  username,
  homeDir,
  ...
}:
let
  cfg = config.services.sing-box;

  genCfg = cfg.configGeneration;
  configFile = genCfg.configDir + "/config.json";
  extraArgsStr = lib.escapeShellArgs genCfg.extraArgs;

  ## Wrapper script for Darwin: runs sbtpl config generation then execs sing-box
  ## (launchd has no ExecStartPre equivalent)
  darwinSingboxScript =
    if genCfg.enable then
      pkgs.writeShellScript "sing-box-launch" ''
        set -euo pipefail
        test -d ${genCfg.configDir} || mkdir -p ${genCfg.configDir}
        test -h ${configFile} && rm ${configFile}
        ${lib.getExe pkgs.nodejs} ${inputs.sbtpl}/node/base.js \
          -s '${genCfg.sourceUrl}' \
          -p '${genCfg.policyFilter}' \
          -o ${configFile} \
          ${extraArgsStr}
        exec ${lib.getExe cfg.package} run -c ${configFile} -D ${genCfg.configDir}
      ''
    else
      pkgs.writeShellScript "sing-box-launch" ''
        exec ${lib.getExe cfg.package} run -c ${cfg.configPath} -D ${genCfg.configDir}
      '';
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
        default = "/run/sing-box";
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
    services.sing-box.configPath = lib.mkDefault "${homeDir}/.config/sing-box/config.json";
    services.sing-box.configGeneration.configDir = lib.mkDefault "${homeDir}/.cache/sing-box";

    environment.systemPackages = [ cfg.package ];

    system.activationScripts.sing-box.text = ''
      mkdir -p ${genCfg.configDir}
      chown ${username}:staff ${genCfg.configDir}
    '';

    launchd.user.agents.singb = {
      command = "${darwinSingboxScript}";
      serviceConfig = {
        Label = "nixdwn.${username}.singb";
        WorkingDirectory = genCfg.configDir;
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 5;
        StandardOutPath = "/tmp/sing-box.log";
        StandardErrorPath = "/tmp/sing-box.log";
      };
    };
  };
}
