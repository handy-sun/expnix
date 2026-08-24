{
  lib,
  pkgs,
  profileLevel,
  isLinux,
  ...
}:

let
  papirus = "${pkgs.papirus-icon-theme}/share/icons/Papirus/48x48/apps";
in
lib.mkIf (profileLevel.guiBase && isLinux) {
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
