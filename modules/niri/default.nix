{
  pkgs,
  ...
}:
let
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
    gnome-themes-extra # Adwaita theme
    glib # gsettings
    kdePackages.breeze-icons
    swaylock
    fuzzel
    wl-clipboard
    swayimg
    gpu-screen-recorder
    xwayland-satellite
    tokyonight-gtk-theme
    rose-pine-cursor
    papirus-icon-theme
    nemo
    libsForQt5.qt5ct
    mpvpaper
  ];

  hardware.i2c.enable = true;

  services.gnome.gcr-ssh-agent.enable = false;
}
