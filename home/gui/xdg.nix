{
  lib,
  config,
  pkgs,
  myvars,
  isDarwin,
  profileLevel,
  ...
}:

let
  stateHomeDir = config.xdg.stateHome;
  isLinuxDe = (profileLevel.guiBase && !isDarwin);
in
{
  gtk = lib.mkIf isLinuxDe {
    enable = true;
    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = true;
    };
    gtk4.extraConfig = {
      "gtk-application-prefer-dark-theme" = true;
    };
  };

  qt = lib.mkIf isLinuxDe {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "Fusion";
  };

  home.pointerCursor = lib.mkIf isLinuxDe {
    name = "BreezeX-RosePine-Linux";
    package = pkgs.rose-pine-cursor;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = lib.mkIf isLinuxDe {
    XCURSOR_THEME = "BreezeX-RosePine-Linux";
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
  };

  xdg = {
    configFile = lib.mkIf isLinuxDe {
      "gtk-3.0/settings.ini".force = true;
      "gtk-4.0/settings.ini".force = true;
      "gtk-4.0/gtk.css".force = true;
      "niri/config.kdl".source = ../niri/config.kdl;
      "niri/noctalia.kdl".source = ../niri/noctalia.kdl;
    };
    userDirs = {
      enable = isLinuxDe;
      createDirectories = true;
      setSessionVariables = false; # 26.05 default: false
      desktop = stateHomeDir + "/Desktop";
      publicShare = stateHomeDir + "/Public";
      templates = stateHomeDir + "/Templates";
      videos = stateHomeDir + "/Videos";
    };
  };
}
