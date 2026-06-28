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
      sunshine
      moonlight-qt
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      wayclip
      wdisplays
      # thunar
      peazip
      appimage-run
      telegram-desktop
      # rustdesk
      deskflow
    ];
}
