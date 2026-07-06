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
      moonlight-qt # Moonlight client; sunshine host is set up per-host via services.sunshine
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
