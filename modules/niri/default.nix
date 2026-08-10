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
    "xdg/menus/applications.menu".text = ''
      <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
        "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
      <Menu>
        <Name>Applications</Name>
        <DefaultAppDirs/>
        <DefaultDirectoryDirs/>
        <DefaultMergeDirs/>
        <Include>
          <All/>
        </Include>
      </Menu>
    '';
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
    kdePackages.dolphin
    kdePackages.ffmpegthumbs
    libsForQt5.qt5ct
    mpvpaper
    ddcutil
  ];

  hardware.i2c.enable = true;

  services.gnome.gcr-ssh-agent.enable = false;
}
