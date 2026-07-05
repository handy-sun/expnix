{
  pkgs,
  lib,
  inputs,
  profileLevel,
  ...
}:

lib.mkIf profileLevel.guiBase {
  home.packages =
    with pkgs;
    [
      ## mpv-mpris exposes track metadata (incl. embedded album art) over MPRIS
      ## so shells like noctalia show the cover instead of mpv's default icon
      (mpv.override { scripts = [ mpvScripts.mpris ]; })
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
      inputs.mark-shot.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
