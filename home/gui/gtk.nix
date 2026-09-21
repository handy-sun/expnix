## Icon theme + GTK plumbing, previously hand-maintained in ~/.icons and settings.ini.
{
  config,
  lib,
  pkgs,
  profileLevel,
  isLinux,
  ...
}:
let
  iconThemeName = "hicolor-plus";
  kdedConfig = config.xdg.configHome + "/kded6rc";
  kwriteconfig = lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6";
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

  ## kde-gtk-config is a plasma6 required package, so excludePackages (which only
  ## filters optional ones) cannot drop it. Its kded6 module rewrites
  ## gtk-{3,4}.0/{colors,gtk}.css whenever a KDE app activates kded6 under niri;
  ## the GFileMonitor signal that follows segfaults GTK/GIO clients on a stale
  ## closure. hm owns the GTK config here, so keep the syncer off. Reapplied each
  ## activation because kded6 rewrites kded6rc itself.
  home.activation.disableKdedGtkConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${kwriteconfig} --file ${lib.escapeShellArg kdedConfig} --group Module-gtkconfig --key autoload false
  '';
}
