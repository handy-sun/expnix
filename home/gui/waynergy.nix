{
  lib,
  pkgs,
  networkingVars,
  profileLevel,
  ...
}:

lib.mkIf (profileLevel.guiBase && pkgs.stdenv.isLinux) {
  xdg.configFile."waynergy/config.ini".text = ''
    host = ${networkingVars.hosts.ms7d.addresses.eth.ipv4}
    port = 24800
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

  systemd.user.services.waynergy = {
    Unit = {
      Description = "Waynergy client for the Windows Barrier server";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${lib.getExe' pkgs.waynergy "waynergy"} --backend uinput";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
