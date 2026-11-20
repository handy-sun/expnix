{
  config,
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
  };

  ## VNC for the niri session. Clients authenticate through PAM with the
  ## system password; TLS uses a self-signed pair generated on first activation.
  ## relax_encryption keeps Apple/legacy clients usable on trusted networks.
  services.wayvnc = {
    enable = true;
    autoStart = true;
    systemdTarget = "niri.service";
    settings = {
      address = "0.0.0.0";
      port = 5900;
      enable_auth = true;
      enable_pam = true;
      relax_encryption = true;
      certificate_file = "${config.home.homeDirectory}/.config/wayvnc/cert.pem";
      private_key_file = "${config.home.homeDirectory}/.config/wayvnc/key.pem";
    };
  };

  home.activation.wayvncTls = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dir="$HOME/.config/wayvnc"
    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    if [ ! -s "$dir/key.pem" ] || [ ! -s "$dir/cert.pem" ]; then
      ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 \
        -nodes -keyout "$dir/key.pem" -out "$dir/cert.pem" -subj "/CN=wayvnc" 2>/dev/null
    fi
    chmod 600 "$dir/key.pem"
  '';
}
