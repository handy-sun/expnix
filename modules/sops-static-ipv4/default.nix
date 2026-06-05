{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.networking.sopsStaticIpv4;

  addressSecret = "sops-static-ipv4-address";
  gatewaySecret = "sops-static-ipv4-gateway";
  envTemplate = "sops-static-ipv4.env";
  serviceName = "sops-static-ipv4";
in
{
  options.networking.sopsStaticIpv4 = {
    enable = lib.mkEnableOption "static IPv4 configuration loaded from SOPS";

    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = "SOPS YAML file containing the IPv4 address and default gateway.";
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "eth0";
      description = "Network interface to configure.";
    };

    addressKey = lib.mkOption {
      type = lib.types.str;
      default = "ip";
      description = "YAML key containing the IPv4 address.";
    };

    gatewayKey = lib.mkOption {
      type = lib.types.str;
      default = "gateway";
      description = "YAML key containing the default gateway.";
    };

    defaultPrefixLength = lib.mkOption {
      type = lib.types.ints.between 0 32;
      default = 24;
      description = "Prefix length to append when the SOPS address has no CIDR suffix.";
    };

    unmanagedByNetworkManager = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to mark the interface as unmanaged by NetworkManager.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        ${addressSecret} = {
          sopsFile = cfg.sopsFile;
          key = cfg.addressKey;
        };
        ${gatewaySecret} = {
          sopsFile = cfg.sopsFile;
          key = cfg.gatewayKey;
        };
      };

      templates.${envTemplate} = {
        content = ''
          SOPS_STATIC_IPV4_ADDRESS=${config.sops.placeholder.${addressSecret}}
          SOPS_STATIC_IPV4_GATEWAY=${config.sops.placeholder.${gatewaySecret}}
        '';
        restartUnits = [ "${serviceName}.service" ];
      };
    };

    systemd.services.${serviceName} = {
      description = "Apply static IPv4 settings from SOPS";
      wantedBy = [ "multi-user.target" ];
      before = [
        "network-online.target"
        "sshd.service"
      ];
      wants = [ "network-pre.target" ];
      after = [ "network-pre.target" ];
      path = [ pkgs.iproute2 ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        EnvironmentFile = config.sops.templates.${envTemplate}.path;
      };
      script = ''
        set -euo pipefail

        address="$SOPS_STATIC_IPV4_ADDRESS"
        case "$address" in
          */*) ;;
          *) address="$address/${toString cfg.defaultPrefixLength}" ;;
        esac

        ip link set dev ${lib.escapeShellArg cfg.interface} up
        ip address replace "$address" dev ${lib.escapeShellArg cfg.interface}
        ip route replace default via "$SOPS_STATIC_IPV4_GATEWAY" dev ${lib.escapeShellArg cfg.interface}
      '';
    };

    networking.networkmanager.unmanaged = lib.mkIf cfg.unmanagedByNetworkManager [
      "interface-name:${cfg.interface}"
    ];
  };
}
