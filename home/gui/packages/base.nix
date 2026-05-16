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
      zed-editor
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      wayclip
      wdisplays
      thunar
      peazip
      appimage-run
    ];
}
