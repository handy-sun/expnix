{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mtg;
  format = pkgs.formats.toml { };

  defaults = {
    bind-to = "0.0.0.0:443";
    concurrency = 8192;
    tcp-buffer = "128kb";
    prefer-ip = "only-ipv4";
    tolerate-time-skewness = "5s";
    domain-fronting.port = 443;
    network = {
      dns = "1.1.1.1";
      proxies = [ ];
      timeout = {
        tcp = "5s";
        http = "10s";
        idle = "1m";
      };
    };
    defense = {
      anti-replay = {
        enabled = true;
        max-size = "1mib";
        error-rate = 0.001;
      };
      blocklist = {
        enabled = true;
        download-concurrency = 2;
        urls = [ ];
        update-each = "24h";
      };
    };
    stats.statsd = {
      enabled = true;
      address = "127.0.0.1:9833";
      metric-prefix = "mtg";
      tag-format = "datadog";
    };
  };

  settings = lib.recursiveUpdate defaults cfg.settings;
  configFile = format.generate "mtg.toml" settings;
in
{
  options.services.mtg = {
    enable = lib.mkEnableOption "mtg Telegram MTProto proxy";

    package = lib.mkPackageOption pkgs "mtg" { };

    settings = lib.mkOption {
      type = format.type;
      default = { };
      description = ''
        mtg TOML settings merged on top of module defaults via recursiveUpdate.
        At minimum, set `secret`. Other fields override the defaults.

        Defaults:
        ${lib.generators.toPretty { } defaults}
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = settings ? secret;
        message = "services.mtg.settings.secret must be set";
      }
    ];

    systemd.services.mtg = {
      description = "mtg Telegram MTProto proxy";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} run ${configFile}";
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
