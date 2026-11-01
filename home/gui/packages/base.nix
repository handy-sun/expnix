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
  markShot = inputs.mark-shot.packages.${archSystem}.default.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    ## 0.1.62 ships OCR as a native Qt plugin that is silently skipped unless
    ## onnxruntime (headers/CMake config live in its dev output) is found.
    buildInputs = (old.buildInputs or [ ]) ++ [
      pkgs.onnxruntime
      pkgs.onnxruntime.dev
    ];
    postInstall = (old.postInstall or "") + ''
      wrapProgram $out/bin/mark-shot \
        --set QT_QPA_PLATFORMTHEME generic
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
      rayburst
      markShot
      netcattyPkg
    ]
    ++ lib.optionals isDarwin [ utm ];
}
