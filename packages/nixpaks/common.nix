{
  config,
  lib,
  pkgs,
  sloth,
  ...
}:

{
  locale.enable = true;
  fonts.enable = false;

  gpu = {
    enable = true;
    provider = "nixos";
  };

  etc.sslCertificates.enable = true;

  dbus = {
    enable = true;
    policies = {
      "${config.flatpak.appId}" = "own";
      "${config.flatpak.appId}.*" = "own";
      "org.freedesktop.DBus" = "talk";
      "org.gtk.vfs" = "talk";
      "org.gtk.vfs.*" = "talk";
      "ca.desrt.dconf" = "talk";
      "org.a11y.Bus" = "talk";
      "org.freedesktop.portal.Desktop" = "see";
      "org.freedesktop.portal.Documents" = "talk";
      "org.freedesktop.portal.FileTransfer" = "talk";
      "org.freedesktop.Notifications" = "talk";
      "org.kde.StatusNotifierWatcher" = "talk";
      "org.freedesktop.FileManager1" = "talk";
      "org.freedesktop.appearance" = "talk";
      "org.freedesktop.appearance.*" = "talk";
      "org.freedesktop.portal.Fcitx" = "talk";
      "org.freedesktop.portal.Fcitx.*" = "talk";
    }
    // builtins.listToAttrs (
      map (id: lib.nameValuePair "org.kde.StatusNotifierItem-${toString id}-1" "own") (lib.range 2 11)
    );

    rules = {
      call = {
        "org.freedesktop.portal.Desktop" = [
          "org.freedesktop.DBus.Properties.Get@/org/freedesktop/portal/desktop"
          "org.freedesktop.DBus.Properties.GetAll@/org/freedesktop/portal/desktop"
          "org.freedesktop.portal.Account.GetUserInformation"
          "org.freedesktop.portal.Camera.*"
          "org.freedesktop.portal.Documents.*"
          "org.freedesktop.portal.FileChooser.*"
          "org.freedesktop.portal.FileTransfer.*"
          "org.freedesktop.portal.NetworkMonitor.*"
          "org.freedesktop.portal.Notification.*"
          "org.freedesktop.portal.OpenURI.*"
          "org.freedesktop.portal.ProxyResolver.*"
          "org.freedesktop.portal.Request"
          "org.freedesktop.portal.Settings.Read"
          "org.freedesktop.portal.Settings.ReadAll"
        ];
        "org.freedesktop.portal.Documents" = [ "*" ];
        "org.freedesktop.portal.FileTransfer" = [ "*" ];
        "org.freedesktop.portal.Fcitx" = [ "*" ];
        "org.freedesktop.portal.Fcitx.*" = [ "*" ];
        "org.freedesktop.Notifications.*" = [ "*" ];
        "org.freedesktop.FileManager1" = [ "*" ];
      };
      broadcast."org.freedesktop.portal.*" = [ "@/org/freedesktop/portal/*" ];
    };
  };

  bubblewrap = {
    network = true;
    newSession = true;
    dieWithParent = true;

    sockets = {
      x11 = true;
      pulse = true;
    };

    bind.rw = [
      [
        (sloth.mkdir sloth.appConfigDir)
        sloth.xdgConfigHome
      ]
      [
        (sloth.mkdir sloth.appDataDir)
        sloth.xdgDataHome
      ]
      [
        (sloth.mkdir sloth.appCacheDir)
        sloth.xdgCacheHome
      ]
      sloth.xdgDownloadDir
      (sloth.concat' sloth.runtimeDir "/at-spi/bus")
      (sloth.concat' sloth.runtimeDir "/dconf")
      (sloth.concat' sloth.runtimeDir "/gvfsd")
    ];

    bind.ro = [
      "/etc/fonts"
      "/etc/localtime"
      (sloth.concat' sloth.runtimeDir "/doc")
      (sloth.concat' sloth.xdgConfigHome "/fontconfig")
      (sloth.concat' sloth.xdgConfigHome "/gtk-2.0")
      (sloth.concat' sloth.xdgConfigHome "/gtk-3.0")
      (sloth.concat' sloth.xdgConfigHome "/gtk-4.0")
      (sloth.concat' sloth.xdgConfigHome "/kdeglobals")
    ];

    bind.dev = map (id: "/dev/video${toString id}") (lib.range 0 9);
    tmpfs = [ "/tmp" ];

    env = {
      XDG_DATA_DIRS = lib.makeSearchPath "share" [
        pkgs.adwaita-icon-theme
        pkgs.shared-mime-info
      ];
      XCURSOR_PATH = lib.concatStringsSep ":" [
        "${pkgs.adwaita-icon-theme}/share/icons"
        "${pkgs.adwaita-icon-theme}/share/pixmaps"
      ];
    };
  };
}
