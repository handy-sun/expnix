{
  pkgs,
  lib,
  inputs,
  profileLevel,
  isDarwin,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
lib.mkIf profileLevel.guiBase {
  home.packages =
    with pkgs;
    [
      moonlight-qt # Moonlight client; sunshine host is set up per-host via services.sunshine
      obsidian
    ]
    ++ lib.optionals (!isDarwin) [
      ## mpv-mpris (MPRIS/D-Bus) is Linux-only, so mpv carries the mpris script here
      (mpv.override { scripts = [ mpvScripts.mpris ]; })
      filezilla
      nwg-look
      pavucontrol
      gnome-disk-utility
      mission-center
      kdePackages.filelight
      obs-studio
      wayclip
      waynergy
      wdisplays
      wineWow64Packages.stable

      ## WPS China has the best compatibility with Chinese Office documents
      ## and the macOS WPS installations used by colleagues.
      wpsoffice-cn
      ## Okular handles PDF annotations and navigation well on Wayland.
      kdePackages.okular

      peazip
      appimage-run
      telegram-desktop
      inputs.rustdesk-flutter-nixpkgs.legacyPackages.${system}.rustdesk-flutter
      inputs.mark-shot.packages.${system}.default
    ]
    ++ lib.optionals isDarwin [
      mpv
      utm
    ];
}
