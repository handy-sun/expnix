{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  baseConfig = pkgs.writeText "niri-base-config.kdl" ''
    include "${pkgs.niri.src}/resources/default-config.kdl"
  '';
  noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  programs.niri.enable = true;

  environment.etc = {
    "niri/config.kdl".source = baseConfig;
  };

  environment.systemPackages = [
    noctalia
  ]
  ++ (with pkgs; [
    gnome-themes-extra # Adwaita theme
    glib # gsettings
    kdePackages.breeze-icons
    swaylock
    fuzzel
    wl-clipboard
  ]);

  hardware.i2c.enable = true;

  services.gnome.gcr-ssh-agent.enable = false;
}
