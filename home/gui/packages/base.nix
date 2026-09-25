{
  pkgs,
  lib,
  inputs,
  myvars,
  profileLevel,
  isDarwin,
  ...
}:
let
  inherit (myvars) archSystem;
  markShotOcrPython = pkgs.python314.withPackages (pythonPackages: [ pythonPackages.rapidocr ]);
  markShot = inputs.mark-shot.packages.${archSystem}.default.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/mark-shot \
        --set QT_QPA_PLATFORMTHEME generic
      wrapProgram $out/bin/mark-shot-ocr \
        --set MARK_SHOT_OCR_PYTHON ${markShotOcrPython}/bin/python
    '';
  });
  ## buildFHSEnv builds via buildCommand, so postInstall is skipped: the wrapper
  ## must go through extraInstallCommands. Pin the store explicitly because
  ## Chromium's autodetection does not know niri and falls back to plaintext.
  netcattyPkg = inputs.netcatty.packages.${archSystem}.default.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    extraInstallCommands = (old.extraInstallCommands or "") + ''
      wrapProgram $out/bin/netcatty --add-flags --password-store=gnome-libsecret
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
      rustdesk-flutter
      markShot
      netcattyPkg
    ]
    ++ lib.optionals isDarwin [ utm ];
}
