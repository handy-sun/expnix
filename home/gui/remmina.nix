{
  lib,
  pkgs,
  profileLevel,
  ...
}:

lib.mkIf (profileLevel.guiBase && pkgs.stdenv.isLinux) {
  services.remmina = {
    enable = true;
    addRdpMimeTypeAssoc = true;
    systemdService.enable = false;
  };

  # Keep the legacy/manual XDG autostart entry inert. The Home Manager
  # systemdService option only controls the managed remmina.service unit.
  xdg.configFile."autostart/remmina-applet.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Version=1.0
      Name=Remmina panel applet
      Comment=Open Remmina from the application launcher when needed
      Icon=org.remmina.Remmina
      Exec=remmina -i
      Terminal=false
      Type=Application
      Hidden=true
    '';
  };
}
