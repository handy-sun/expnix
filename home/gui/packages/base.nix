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
      # fuzzel
      thunar
      peazip
    ];
}
