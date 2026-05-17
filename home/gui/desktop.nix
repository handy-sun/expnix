{
  lib,
  pkgs,
  inputs,
  profileLevel,
  ...
}:
let
  niriUserConfig = pkgs.writeText "niri-user-config.kdl" ''
    include "${pkgs.niri.src}/resources/default-config.kdl"
    include "extra.kdl"
    include "noctalia.kdl"
  '';
  niriCfgDir = inputs.my-dotfiles + "/.config/niri";
in
lib.mkIf (profileLevel.guiBase && pkgs.stdenv.isLinux) {
  # gtk = {
  #   iconTheme = {
  #     name = "Papirus";
  #     package = pkgs.papirus-icon-theme;
  #   };
  #   gtk3.extraConfig = {
  #     "gtk-application-prefer-dark-theme" = true;
  #   };
  #   gtk4.extraConfig = {
  #     "gtk-application-prefer-dark-theme" = true;
  #   };
  # };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "Fusion";
  };

  home.pointerCursor = {
    name = "BreezeX-RosePine-Linux";
    package = pkgs.rose-pine-cursor;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = {
    XCURSOR_THEME = "BreezeX-RosePine-Linux";
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
  };

  xdg.configFile = {
    # "gtk-3.0/settings.ini".force = true;
    # "gtk-4.0/settings.ini".force = true;
    # "gtk-4.0/gtk.css".force = true;
    "niri/config.kdl".source = niriUserConfig;
    "niri/extra.kdl".source = niriCfgDir + "/extra.kdl";
    "niri/noctalia.kdl".source = niriCfgDir + "/noctalia.kdl";
  };
}
