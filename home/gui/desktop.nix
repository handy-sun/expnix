{
  lib,
  pkgs,
  inputs,
  myutils,
  profileLevel,
  isLinux,
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

      // wemeet's Xwayland PipeWire hook does not advertise DRM modifiers.
      // Force the compositor to offer a plain-memory format for screencasting.
      debug {
          force-pipewire-invalid-modifier
      }
    ''}

    cursor {
        xcursor-theme "${cursorThemeName}"
        xcursor-size ${toString cursorSize}
    }
  '';
  niriCfgDir = inputs.my-dotfiles + "/.config/niri";
  niriWindowPicker = pkgs.writeShellApplication {
    name = "niri-window-picker";
    runtimeInputs = [
      pkgs.fuzzel
      pkgs.jq
      pkgs.niri
    ];
    text = builtins.readFile (myutils.relativeToRoot "scripts/niri-window-picker.sh");
  };
  bibataRainbowModern =
    pkgs.callPackage (myutils.relativeToRoot "packages/bibata-rainbow-modern.nix")
      { };
in
lib.mkIf (profileLevel.guiBase && isLinux) {
  home.packages = [ niriWindowPicker ];
  home.file.".local/bin/niri-window-picker".source = "${niriWindowPicker}/bin/niri-window-picker";

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
