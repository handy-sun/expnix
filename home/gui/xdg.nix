{
  lib,
  pkgs,
  config,
  profileLevel,
  isLinux,
  ...
}:

let
  stateHomeDir = config.xdg.stateHome;
  defaultBrowser = "helium.desktop";
  defaultFileManager = "org.kde.dolphin.desktop";
  defaultImageViewer = "swayimg.desktop";
  defaultPdfViewer = "org.kde.okular.desktop";
  imageMimeTypes = [
    "image/avif"
    "image/bmp"
    "image/gif"
    "image/heif"
    "image/jpeg"
    "image/jpg"
    "image/jxl"
    "image/pbm"
    "image/pjpeg"
    "image/png"
    "image/svg+xml"
    "image/tiff"
    "image/webp"
    "image/x-bmp"
    "image/x-exr"
    "image/x-png"
    "image/x-portable-anymap"
    "image/x-portable-bitmap"
    "image/x-portable-graymap"
    "image/x-portable-pixmap"
    "image/x-targa"
    "image/x-tga"
  ];
  ## Linux Desktop Environments (DEs) typically use XDG Base Directory Specification for configuration and user directories. This setup is not relevant for macOS (Darwin), which has its own conventions. Therefore, we check if the profile level indicates a GUI base and ensure it's not Darwin to determine if we should apply the XDG configuration.
  isLinuxDe = (profileLevel.guiBase && isLinux);
  wpsPackage = pkgs.wpsoffice-cn;
  wpsImeEnv = "${pkgs.coreutils}/bin/env QT_QPA_PLATFORM=xcb QT_IM_MODULE=fcitx GTK_IM_MODULE=fcitx XMODIFIERS=@im=fcitx";
  wpsDesktop =
    desktop: executable:
    lib.replaceStrings
      [ "Exec=${executable} " ]
      [ "Exec=${wpsImeEnv} ${wpsPackage}/bin/${executable} " ]
      (builtins.readFile "${wpsPackage}/share/applications/${desktop}");
in
{
  xdg = {
    userDirs = {
      enable = isLinuxDe;
      createDirectories = true;
      setSessionVariables = false; # 26.05 default: false
      desktop = stateHomeDir + "/Desktop";
      publicShare = stateHomeDir + "/Public";
      templates = stateHomeDir + "/Templates";
      videos = stateHomeDir + "/Videos";
    };

    ## WPS bundles its own Qt and currently fails to activate Fcitx through
    ## the native Wayland frontend. Keep the workaround app-local so other
    ## Qt/GTK applications retain their native input-method paths.
    dataFile = lib.mkIf isLinuxDe {
      "applications/wps-office-wps.desktop".text = wpsDesktop "wps-office-wps.desktop" "wps";
      "applications/wps-office-et.desktop".text = wpsDesktop "wps-office-et.desktop" "et";
      "applications/wps-office-wpp.desktop".text = wpsDesktop "wps-office-wpp.desktop" "wpp";
    };

    mimeApps = {
      enable = isLinuxDe;
      defaultApplications = {
        "inode/directory" = [ defaultFileManager ];
        "text/html" = [ defaultBrowser ];
        "x-scheme-handler/http" = [ defaultBrowser ];
        "x-scheme-handler/https" = [ defaultBrowser ];
        "application/pdf" = [ defaultPdfViewer ];
        "application/vnd.oasis.opendocument.text" = [ "wps-office-wps.desktop" ];
        "application/vnd.oasis.opendocument.spreadsheet" = [ "wps-office-et.desktop" ];
        "application/vnd.oasis.opendocument.presentation" = [ "wps-office-wpp.desktop" ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
          "wps-office-wps.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [
          "wps-office-et.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [
          "wps-office-wpp.desktop"
        ];
        "x-scheme-handler/mpv" = [ "mpv-handler.desktop" ];
      }
      // lib.genAttrs imageMimeTypes (_: [ defaultImageViewer ]);
    };
  };
}
