{
  lib,
  config,
  pkgs,
  myutils,
  profileLevel,
  ...
}:
let
  enableHelium = profileLevel.guiHeavy && pkgs.stdenv.hostPlatform.system == "x86_64-linux";
  helium = pkgs.callPackage (myutils.relativeToRoot "packages/helium.nix") { };
in
lib.mkIf profileLevel.guiBase {
  home.packages = lib.optionals enableHelium [ helium ];

  programs.chromium = {
    enable = profileLevel.guiHeavy;
  };
  programs.firefox = {
    enable = profileLevel.guiHeavy;
    configPath = config.xdg.configHome + "/mozilla/firefox";
  };

  xdg = lib.mkIf enableHelium {
    dataFile = {
      "applications/helium.desktop".source = "${helium}/share/applications/helium.desktop";
      "icons/hicolor/256x256/apps/helium.png".source =
        "${helium}/share/icons/hicolor/256x256/apps/helium.png";
    };

    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = [ "helium.desktop" ];
        "x-scheme-handler/http" = [ "helium.desktop" ];
        "x-scheme-handler/https" = [ "helium.desktop" ];
      };
    };
  };
}
