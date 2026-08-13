{
  lib,
  pkgs,
  mkNixPak,
  mkNixPakAppWrapper,
}:
let
  appId = "com.tencent.wemeet";
  appPackage = mkNixPakAppWrapper pkgs.wemeet {
    binPath = "bin/wemeet-xwayland";
  };
  wrapped = mkNixPak {
    config =
      { lib, ... }:
      {
        imports = [ ./common.nix ];

        app.package = appPackage;
        flatpak.appId = appId;

        dbus = {
          policies = {
            "org.freedesktop.Notifications" = "talk";
            "org.gnome.Shell.Screencast" = "talk";
            "org.kde.StatusNotifierWatcher" = "talk";
          };
          rules.call."org.freedesktop.portal.Desktop" = lib.mkAfter [
            "org.freedesktop.portal.RemoteDesktop.*"
            "org.freedesktop.portal.ScreenCast.*"
            "org.freedesktop.portal.Session.Close"
          ];
        };

        bubblewrap = {
          sockets = {
            wayland = lib.mkForce false;
            pipewire = true;
            x11 = true;
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
      desktopName = "Tencent Meeting";
      genericName = "Wemeet";
      comment = "Tencent cloud video conferencing";
      exec = "${executable} %u";
      icon = "${pkgs.wemeet}/share/icons/hicolor/scalable/apps/wemeet.svg";
      terminal = false;
      type = "Application";
      categories = [ "Office" ];
      keywords = [
        "wemeet"
        "tencent"
        "meeting"
      ];
      mimeTypes = [ "x-scheme-handler/wemeet" ];
      extraConfig.X-Flatpak = appId;
    })
  ];
}
