{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tailscale.derperCustom;
  certName = cfg.hostname;
  prepareCerts = pkgs.writeShellScript "tailscale-derper-prepare-certs" ''
    set -eu
    install -d -o derp -g derp -m 0700 /run/tailscale-derper-certs
    install -o derp -g derp -m 0600 ${lib.escapeShellArg "${cfg.certificateDirectory}/fullchain.pem"} ${lib.escapeShellArg "/run/tailscale-derper-certs/${certName}.crt"}
    install -o derp -g derp -m 0600 ${lib.escapeShellArg "${cfg.certificateDirectory}/key.pem"} ${lib.escapeShellArg "/run/tailscale-derper-certs/${certName}.key"}
  '';
in
{
  options.services.tailscale.derperCustom = {
    enable = lib.mkEnableOption "Tailscale DERP relay server";

    openFirewall = lib.mkEnableOption "the DERP and STUN ports in the firewall";

    hostname = lib.mkOption {
      type = lib.types.str;
      description = "TLS hostname advertised by the DERP server.";
    };

    certificateDirectory = lib.mkOption {
      type = lib.types.path;
      description = "ACME certificate directory containing fullchain.pem and key.pem.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 443;
    };

    stunPort = lib.mkOption {
      type = lib.types.port;
      default = 3478;
    };

    package = lib.mkPackageOption pkgs [ "tailscale" "derper" ] { };
  };

  config = lib.mkIf cfg.enable {
    users.users.derp = {
      isSystemUser = true;
      group = "derp";
    };
    users.groups.derp = { };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.stunPort ];
    };

    systemd.services.tailscale-derper = {
      path = [ pkgs.coreutils ];
      description = "Tailscale DERP relay server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "derp";
        Group = "derp";
        StateDirectory = "derper";
        RuntimeDirectory = "tailscale-derper-certs";
        ExecStartPre = [ "+${prepareCerts}" ];
        ExecStart = "${lib.getExe' cfg.package "derper"} -c /var/lib/derper/derper.key -hostname ${cfg.hostname} -certmode manual -certdir /run/tailscale-derper-certs -a :${toString cfg.port} -http-port -1 -stun-port ${toString cfg.stunPort}";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          "/var/lib/derper"
          "/run/tailscale-derper-certs"
        ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
    };
  };
}
