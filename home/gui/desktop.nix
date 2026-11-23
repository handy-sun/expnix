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
  home.packages = [
    niriWindowPicker
    pkgs.wayvnc
  ];
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

  ## VNC for the niri session. wayvnc does its own password auth over TLS: PAM
  ## is unusable here because pam_unix's account phase needs root, which a user
  ## service does not have. The password and the self-signed pair are generated
  ## once on activation and live outside the store; read the password with
  ## `cat ~/.config/wayvnc/password`.

  ## The home-manager wayvnc module insists on owning config.toml (and needs
  ## settings.address), but the password has to stay outside the store, so the
  ## unit and the config file are wired by hand below.
  systemd.user.services.wayvnc = {
    Unit = {
      Description = "wayvnc VNC server";
      Documentation = [ "man:wayvnc(1)" ];
      After = [ "niri.service" ];
      PartOf = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.wayvnc}";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };

  home.activation.wayvncConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dir="$HOME/.config/wayvnc"
    ${pkgs.coreutils}/bin/mkdir -p "$dir"
    if [ ! -s "$dir/key.pem" ] || [ ! -s "$dir/cert.pem" ]; then
      ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 \
        -nodes -keyout "$dir/key.pem" -out "$dir/cert.pem" -subj "/CN=wayvnc" 2>/dev/null
    fi
    if [ ! -s "$dir/password" ]; then
      ${pkgs.openssl}/bin/openssl rand -base64 24 \
        | ${pkgs.coreutils}/bin/tr -dc 'A-Za-z0-9' \
        | ${pkgs.coreutils}/bin/head -c 12 > "$dir/password"
    fi
    ${pkgs.coreutils}/bin/chmod 600 "$dir/key.pem" "$dir/password"
    pw="$(${pkgs.coreutils}/bin/cat "$dir/password")"
    ${pkgs.coreutils}/bin/printf '%s\n' \
      'address=0.0.0.0' \
      'port=5900' \
      'enable_auth=true' \
      'relax_encryption=true' \
      'username=qi' \
      "certificate_file=$dir/cert.pem" \
      "private_key_file=$dir/key.pem" \
      "password=$pw" > "$dir/config"
  '';
}
