{
  lib,
  pkgs,
  inputs,
  myutils,
  profileLevel,
  hostName ? null,
  ...
}:
let
  cursorThemeName = "Bibata-Rainbow-Modern";
  cursorSize = 28;
  niriUserConfig = pkgs.writeText "niri-user-config.kdl" ''
    include "${pkgs.niri.src}/resources/default-config.kdl"
    include "extra.kdl"
    include "noctalia.kdl"

    ${lib.optionalString (hostName == "buking") ''
      // buking's screen
      output "eDP-1" {
          mode "1920x1080@60.049"
          scale 1.1
          transform "normal"
          position x=0 y=0
      }
    ''}

    cursor {
        xcursor-theme "${cursorThemeName}"
        xcursor-size ${toString cursorSize}
    }
  '';
  niriCfgDir = inputs.my-dotfiles + "/.config/niri";
  bibataRainbowModern =
    pkgs.callPackage (myutils.relativeToRoot "packages/bibata-rainbow-modern.nix")
      { };
in
lib.mkIf (profileLevel.guiBase && pkgs.stdenv.isLinux) {
  # qt = {
  #   enable = true;
  #   platformTheme.name = "qtct";
  #   style.name = "Fusion";
  # };

  home.pointerCursor = {
    enable = true;
    name = cursorThemeName;
    package = bibataRainbowModern;
    size = cursorSize;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables = {
    XCURSOR_THEME = cursorThemeName;
    XCURSOR_SIZE = toString cursorSize;
    NIXOS_OZONE_WL = "1";
  };

  xdg.configFile = {
    "niri/config.kdl".source = niriUserConfig;
    "niri/extra.kdl".source = niriCfgDir + "/extra.kdl";
    "niri/noctalia.kdl".source = niriCfgDir + "/noctalia.kdl";
  };
}
