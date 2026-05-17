{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  programs.niri.enable = true;

  qt.enable = true;

  environment.systemPackages = [
    noctalia
  ]
  ++ (with pkgs; [
    xwayland-satellite
    tokyonight-gtk-theme
    swayimg
    rose-pine-cursor
    papirus-icon-theme
    nemo
    fuzzel
    gpu-screen-recorder
    wl-clipboard
    libsForQt5.qt5ct
    mpvpaper
    kdePackages.breeze-icons
    glib # gsettings
  ]);

  hardware.i2c.enable = true;

  services.gnome.gcr-ssh-agent.enable = false;
}
