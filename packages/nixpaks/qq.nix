{
  lib,
  pkgs,
  mkNixPak,
  mkNixPakAppWrapper,
}:
let
  appId = "com.qq.QQ";
  appPackage = mkNixPakAppWrapper pkgs.qq {
    binPath = "bin/qq";
    prefixLibraries = [
      pkgs.libx11
      pkgs.libkrb5
      pkgs.stdenv.cc.cc
    ];
  };
  wrapped = mkNixPak {
    config = {
      imports = [ ./common.nix ];

      app.package = appPackage;
      flatpak.appId = appId;

      bubblewrap.sockets.wayland = true;

      dbus.policies = {
        "org.freedesktop.Notifications" = "talk";
        "org.freedesktop.ScreenSaver" = "talk";
        "org.freedesktop.login1" = "talk";
        "org.kde.StatusNotifierWatcher" = "talk";
      };
    };
  };
  executable = lib.getExe wrapped.config.script;
in
pkgs.buildEnv {
  inherit (wrapped.config.script) name meta passthru;
  paths = [
    wrapped.config.script
    (pkgs.makeDesktopItem {
      name = appId;
      desktopName = "QQ";
      genericName = "QQ";
      comment = "Tencent QQ instant messaging";
      exec = "${executable} %U";
      icon = "${pkgs.qq}/share/icons/hicolor/512x512/apps/qq.png";
      startupNotify = true;
      terminal = false;
      type = "Application";
      categories = [
        "InstantMessaging"
        "Network"
      ];
      extraConfig.X-Flatpak = appId;
    })
  ];
}
