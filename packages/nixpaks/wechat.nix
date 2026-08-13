{
  lib,
  pkgs,
  mkNixPak,
  mkNixPakAppWrapper,
}:
let
  appId = "com.tencent.WeChat";
  appPackage = mkNixPakAppWrapper pkgs.wechat { };
  wrapped = mkNixPak {
    config =
      { lib, sloth, ... }:
      {
        imports = [ ./common.nix ];

        app.package = appPackage;
        flatpak.appId = appId;

        dbus.policies = {
          "org.freedesktop.FileManager1" = "talk";
          "org.freedesktop.Notifications" = "talk";
          "org.kde.StatusNotifierWatcher" = "talk";
        };

        bubblewrap = {
          sockets = {
            wayland = lib.mkForce false;
            x11 = true;
          };
          bind.ro = [
            "/etc/passwd"
            "/etc/machine-id"
          ];
          bind.rw = [
            [
              (sloth.mkdir (sloth.concat' sloth.appDataDir "/xwechat_files"))
              (sloth.concat' sloth.homeDir "/xwechat_files")
            ]
          ];
          env = {
            QT_QPA_PLATFORM = "xcb";
            QT_AUTO_SCREEN_SCALE_FACTOR = "1";
            QT_IM_MODULE = "fcitx";
            GTK_IM_MODULE = "fcitx";
          };
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
      desktopName = "WeChat";
      genericName = "WeChat";
      comment = "Tencent WeChat messaging and calling";
      exec = "${executable} %U";
      icon = "${pkgs.wechat}/share/icons/hicolor/256x256/apps/wechat.png";
      startupNotify = true;
      terminal = false;
      type = "Application";
      categories = [
        "InstantMessaging"
        "Network"
      ];
      keywords = [
        "wechat"
        "weixin"
      ];
      extraConfig.X-Flatpak = appId;
    })
  ];
}
