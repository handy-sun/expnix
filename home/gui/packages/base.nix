{
  pkgs,
  lib,
  inputs,
  profileLevel,
  ...
}:
let
  inherit (pkgs.stdenv) isDarwin;
  inherit (pkgs.stdenv.hostPlatform) system;
in
lib.mkIf profileLevel.guiBase {
  home.packages =
    with pkgs;
    [
      moonlight-qt # Moonlight client; sunshine host is set up per-host via services.sunshine
    ]
    ++ lib.optionals (!isDarwin) [
      ## mpv-mpris (MPRIS/D-Bus) is Linux-only, so mpv carries the mpris script here
      (mpv.override { scripts = [ mpvScripts.mpris ]; })
      wayclip
      wdisplays
      # thunar
      peazip
      appimage-run
      telegram-desktop
      inputs.rustdesk-flutter-nixpkgs.legacyPackages.${system}.rustdesk-flutter
      deskflow
      lan-mouse
      waynergy
      inputs.mark-shot.packages.${system}.default
    ]
    ++ lib.optionals isDarwin [
      mpv
    ];
}
