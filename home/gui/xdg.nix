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
  defaultTextEditor = "nvim.desktop";
  ## Text and source-code MIME types that open in nvim. `text/plain` catches
  ## untyped formats (.nix, .conf, .log); code types are listed explicitly
  ## because xdg-open does not walk the shared-mime-info subclass tree.
  textEditorMimeTypes = [
    ## plain text and markup
    "text/plain"
    "text/markdown"
    "text/x-rst"
    "text/x-org"
    "text/x-tex"
    "text/css"
    "text/csv"
    "text/tab-separated-values"
    "text/x-diff"
    "text/x-makefile"
    "text/x-cmake"
    ## compiled languages
    "text/x-c"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/x-java"
    "text/x-kotlin"
    "text/x-go"
    "text/x-rust"
    ## interpreted languages
    "text/x-python"
    "text/x-python3"
    "text/javascript"
    "application/javascript"
    "text/typescript"
    "text/x-ruby"
    "text/x-lua"
    "text/x-php"
    "application/x-perl"
    "application/x-shellscript"
    "text/x-shellscript"
    ## structured data
    "application/json"
    "application/x-ndjson"
    "application/xml"
    "application/x-yaml"
    "application/yaml"
    "application/toml"
    "application/sql"
  ];
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

    ## The stock nvim.desktop sets Terminal=true, which neither gio nor KIO can
    ## resolve here (no xdg-terminal-exec, no konsole). Launch nvim inside
    ## wezterm explicitly so every opener (Dolphin, gio, portals) works.
    desktopEntries = lib.mkIf isLinuxDe {
      nvim = {
        name = "Neovim";
        genericName = "Text Editor";
        comment = "Edit text and code files";
        exec = "${lib.getExe pkgs.wezterm} start -- nvim %F";
        icon = "nvim";
        terminal = false;
        categories = [
          "Utility"
          "Development"
          "TextEditor"
        ];
        mimeType = textEditorMimeTypes;
      };
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
      // lib.genAttrs textEditorMimeTypes (_: [ defaultTextEditor ])
      // lib.genAttrs imageMimeTypes (_: [ defaultImageViewer ]);
    };
  };
}
