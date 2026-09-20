## Icon theme + GTK plumbing, previously hand-maintained in ~/.icons and settings.ini.
{
  lib,
  profileLevel,
  isLinux,
  ...
}:
let
  iconThemeName = "hicolor-plus";
in
lib.mkIf (profileLevel.guiBase && isLinux) {
  gtk = {
    enable = true;
    ## hicolor keeps the original look; Papirus fills missing names; breeze-dark last resort.
    iconTheme.name = iconThemeName;
    ## Provided system-wide by gnome-themes-extra (modules/niri).
    theme.name = "Adwaita";
    ## Pin gtk4 to the same theme; new hm defaults it to null below stateVersion 26.05.
    gtk4.theme.name = "Adwaita";
    gtk3.extraConfig = {
      gtk-font-name = "Noto Sans, 10";
      gtk-xft-antialias = 1;
      gtk-xft-dpi = 122880;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };
  };

  ## quickshell / portals resolve the icon theme through dconf, not settings.ini.
  dconf.settings."org/gnome/desktop/interface".icon-theme = iconThemeName;

  xdg.dataFile."icons/hicolor-plus/index.theme".text = ''
    [Icon Theme]
    Name=${iconThemeName}
    Comment=hicolor first, Papirus fills missing, breeze-dark last resort
    Inherits=hicolor,Papirus,breeze-dark
  '';
}
