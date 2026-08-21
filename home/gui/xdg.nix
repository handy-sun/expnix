{
  lib,
  pkgs,
  config,
  profileLevel,
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
  isLinuxDe = (profileLevel.guiBase && pkgs.stdenv.isLinux);
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
      }
      // lib.genAttrs imageMimeTypes (_: [ defaultImageViewer ]);
    };
  };
}
