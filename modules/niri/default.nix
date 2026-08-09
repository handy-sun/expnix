{
  pkgs,
  myutils,
  ...
}:
let
  lrc_tty = pkgs.callPackage (myutils.relativeToRoot "packages/lrc_tty.nix") { };
  baseConfig = pkgs.writeText "niri-base-config.kdl" ''
    include "${pkgs.niri.src}/resources/default-config.kdl"
  '';
in
{
  programs.niri.enable = true;

  environment.etc = {
    "niri/config.kdl".source = baseConfig;
  };

  environment.systemPackages = with pkgs; [
    noctalia-shell
    lrc_tty
    gnome-themes-extra # Adwaita theme
    glib # gsettings
    kdePackages.breeze-icons
    swaylock
    fuzzel
    wl-clipboard
    swayimg
    gpu-screen-recorder
    xwayland-satellite
    rose-pine-cursor
    papirus-icon-theme
    nemo
    kdePackages.dolphin
    kdePackages.ffmpegthumbs
    libsForQt5.qt5ct
    mpvpaper
    ddcutil
  ];

  hardware.i2c.enable = true;

  services.gnome.gcr-ssh-agent.enable = false;
}
