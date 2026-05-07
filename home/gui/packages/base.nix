{
  pkgs,
  lib,
  profileLevel,
  ...
}:

lib.mkIf profileLevel.guiBase {
  home.packages =
    with pkgs;
    [
      alacritty
      mpv
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      wezterm
      fuzzel
      swaylock
      wl-clipboard
      wayclip
      wlr-layout-ui
      thunar
      peazip
    ];
}
