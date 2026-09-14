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
  markShotOcrPython = pkgs.python314.withPackages (pythonPackages: [ pythonPackages.rapidocr ]);
  markShot = inputs.mark-shot.packages.${system}.default.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/mark-shot \
        --set QT_QPA_PLATFORMTHEME generic
      wrapProgram $out/bin/mark-shot-ocr \
        --set MARK_SHOT_OCR_PYTHON ${markShotOcrPython}/bin/python
    '';
  });
in
lib.mkIf profileLevel.guiBase {
  home.packages =
    with pkgs;
    [
      moonlight-qt # Moonlight client; sunshine host is set up per-host via services.sunshine
      obsidian
    ]
    ++ lib.optionals (!isDarwin) [
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
      motrix-next
      rustdesk-flutter
      markShot
      inputs.netcatty.packages.${system}.default
    ]
    ++ lib.optionals isDarwin [ utm ];
}
