{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mtg;
  format = pkgs.formats.toml { };

  ## Non-secret settings (excludes secret/bind-to, injected at runtime from files)
  baseSettings = lib.filterAttrs (
    n: _:
    !lib.elem n [
      "secret"
      "bind-to"
    ]
  ) cfg.settings;
  baseConfigFile = format.generate "mtg-base.toml" baseSettings;

  ## Runs as root at service start; merges secret values + static config into /run/mtg/mtg.toml
  genConfig = pkgs.writeShellScript "mtg-gen-config" ''
    {
      printf 'secret = "%s"\n' "$(cat "${cfg.secretFile}")"
      ${lib.optionalString (cfg.bindToFile != null) ''
        printf 'bind-to = "%s"\n' "$(cat "${cfg.bindToFile}")"
      ''}
      cat "${baseConfigFile}"
    } > /run/mtg/mtg.toml
    chown mtg:mtg /run/mtg/mtg.toml
    chmod 400 /run/mtg/mtg.toml
  '';
in
{
  options.services.mtg = {
    enable = lib.mkEnableOption "mtg Telegram MTProto proxy";

    package = lib.mkPackageOption pkgs "mtg" { };

    secretFile = lib.mkOption {
      type = lib.types.path;
      description = "File containing the mtg secret value (e.g., config.sops.secrets.mtg-secret.path).";
    };

    bindToFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "File containing the bind-to address. If null, use settings.bind-to instead.";
    };

    settings = lib.mkOption {
      type = format.type;
      default = { };
      description = ''
        Non-secret mtg TOML settings. Only explicitly set values are written.
        Do NOT set `secret` or `bind-to` here; use secretFile/bindToFile instead.

        Optional sections: defense.anti-replay, defense.blocklist, stats.statsd, etc.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.mtg = {
      isSystemUser = true;
      group = "mtg";
    };
    users.groups.mtg = { };

    systemd.services.mtg = {
      description = "mtg: Telegram MTProto proxy";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStartPre = [ "+${genConfig}" ];
        ExecStart = "${lib.getExe cfg.package} run /run/mtg/mtg.toml";
        RuntimeDirectory = "mtg";
        RuntimeDirectoryMode = "0700";
        User = "mtg";
        Group = "mtg";
        LimitNOFILE = 1048576;
        LimitNPROC = 512;
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
