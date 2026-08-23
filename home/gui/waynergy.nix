{
  config,
  lib,
  pkgs,
  networkingVars,
  profileLevel,
  isLinux,
  ...
}:

let
  waynergyServers = {
    ms7d = {
      host = networkingVars.hosts.ms7d.addresses.lan.ipv4;
      port = 24800;
      autoStart = false;
    };

    p600qi = {
      host = networkingVars.hosts.p600qi.addresses.lan.ipv4;
      port = 24800;
      autoStart = true;
    };
  };

  serverNames = builtins.attrNames waynergyServers;
  autoStartServers = lib.filterAttrs (_: server: server.autoStart or false) waynergyServers;

  configFiles = lib.mapAttrs' (
    serverName: server:
    lib.nameValuePair "waynergy/${serverName}/config.ini" {
      text = ''
        host = ${server.host}
        port = ${toString server.port}
        name = buking

        [tls]
        enable = false

        [raw-keymap]
        offset = 8
        offset_on_explicit = false
        311 = 107
        347 = 133
        348 = 134
        508 = 134
        312 = 108
        349 = 135
        285 = 105
        338 = 118
        327 = 110
        329 = 112
        339 = 119
        335 = 115
        337 = 117
        331 = 113
        328 = 111
        333 = 114
        336 = 116
        309 = 106
        284 = 104
      '';
    }
  ) waynergyServers;

  services = lib.mapAttrs' (
    serverName: server:
    lib.nameValuePair "waynergy-${serverName}" {
      Unit = {
        Description = "Waynergy client for ${serverName}";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        Conflicts = [
          "waynergy.service"
        ]
        ++ map (name: "waynergy-${name}.service") (lib.remove serverName serverNames);
      };

      Service = {
        Environment = [
          "WAYNERGY_CONF_PATH=${config.xdg.configHome}/waynergy/${serverName}"
        ];
        ExecStart = "${lib.getExe' pkgs.waynergy "waynergy"} --backend uinput";
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install.WantedBy = lib.optionals (server.autoStart or false) [ "graphical-session.target" ];
    }
  ) waynergyServers;
in
lib.mkIf (profileLevel.guiBase && isLinux) {
  assertions = [
    {
      assertion = builtins.length (builtins.attrNames autoStartServers) <= 1;
      message = "Only one Waynergy server may auto-start";
    }
  ];

  xdg.configFile = configFiles;
  systemd.user.services = services;
}
