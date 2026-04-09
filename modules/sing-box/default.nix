{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.services.sing-box;
  capabilities = [
    "CAP_NET_ADMIN"
    "CAP_NET_RAW"
    "CAP_NET_BIND_SERVICE"
    "CAP_SYS_PTRACE"
    "CAP_DAC_READ_SEARCH"
  ];
in
{
  options = {
    services.sing-box = {
      enable = lib.mkEnableOption "sing-box universal proxy platform";
      package = lib.mkPackageOption pkgs "sing-box" { };
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
        CapabilityBoundingSet = capabilities;
        AmbientCapabilities = capabilities;
        # WorkingDirectory = "/var/lib/sing-box";
      };
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
