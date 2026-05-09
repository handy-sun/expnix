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
      mpv
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      wezterm
      wayclip
      wdisplays
      thunar
      peazip
      appimage-run
    ];
}
