{
  lib,
  pkgs,
  profileLevel,
  isLinux,
  ...
}:

let
  papirus = "${pkgs.papirus-icon-theme}/share/icons/Papirus/48x48/apps";
  ## Reuse the same mpv override as base.nix so the handler launches the
  ## identical build (the MPRIS script keeps working during playback).
  mpv = pkgs.mpv.override { scripts = [ pkgs.mpvScripts.mpris ]; };

  ## OpenList emits mpv://<percent-encoded-url>; mpv knows nothing about the
  ## mpv:// scheme, so strip it and URL-decode before handing mpv the real URL.
  mpvHandler = pkgs.writeShellScript "mpv-handler" ''
    url="''${1#mpv://}"
    decoded="$(${lib.getExe pkgs.python3} -c 'import sys, urllib.parse; print(urllib.parse.unquote_plus(sys.argv[1]))' "$url")"
    exec ${lib.getExe mpv} "$decoded"
  '';
in
lib.mkIf (profileLevel.guiBase && isLinux) {
  ## Use the desktop-entry module so Home Manager includes this handler in
  ## mimeinfo.cache. A raw xdg.dataFile is not registered with GIO/portals.
  xdg.desktopEntries.mpv-handler = {
    name = "mpv";
    comment = "Play video links from OpenList";
    exec = "${mpvHandler} %u";
    terminal = false;
    mimeType = [ "x-scheme-handler/mpv" ];
    noDisplay = true;
  };

  # These upstream desktop files use icon names that Noctalia does not resolve
  # reliably in the current session. Keep the desktop IDs and commands, but
  # point them at existing Papirus icons through stable Nix store paths.
  xdg.dataFile = {
    "applications/qt5ct.desktop".text = ''
      [Desktop Entry]
      Name=Qt5 Settings
      Comment=Qt5 Configuration Tool
      Exec=qt5ct
      Icon=${papirus}/preferences-desktop-theme.svg
      Terminal=false
      Type=Application
      Categories=Settings;DesktopSettings;Qt;
    '';

    "applications/waynergy.desktop".text = ''
      [Desktop Entry]
      Name=Waynergy
      Comment=A Barrier/Synergy client for Wayland compositors
      Exec=${lib.getExe' pkgs.waynergy "waynergy"}
      Icon=${papirus}/barrier.svg
      Terminal=true
      Type=Application
      Categories=Network;RemoteAccess;
    '';

    "applications/protontricks.desktop".text = ''
      [Desktop Entry]
      Name=Protontricks
      Comment=A simple wrapper that does winetricks things for Proton enabled games
      Exec=protontricks --no-term --gui
      Icon=${papirus}/wine.svg
      Terminal=false
      Type=Application
      Categories=Utility;Game;
      Keywords=Steam;Proton;Wine;Winetricks;
    '';

  };
}
