{
  lib,
  config,
  pkgs,
  myutils,
  profileLevel,
  isLinux,
  ...
}:

let
  zcodeDesktop = pkgs.writeText "zcode.desktop" ''
    [Desktop Entry]
    Name=ZCode
    Comment=ZCode Desktop App
    Exec=${config.home.homeDirectory}/.local/bin/zcode --no-sandbox %U
    TryExec=${config.home.homeDirectory}/.local/bin/zcode
    Terminal=false
    Type=Application
    Icon=zcode
    Categories=Development;
    MimeType=x-scheme-handler/zcode;
    StartupWMClass=ZCode
  '';
  zcode = pkgs.callPackage (myutils.relativeToRoot "packages/zcode.nix") {
    desktopFile = zcodeDesktop;
    desktopFilePath = "${config.home.homeDirectory}/.local/share/applications/zcode.desktop";
  };
  zcodeWrapper = pkgs.writeShellScript "zcode" ''
    exec ${zcode}/bin/zcode "$@"
  '';
in
lib.mkIf (profileLevel.guiBase && isLinux) {
  home.packages = [ zcode ];

  home.file.".local/bin/zcode".source = zcodeWrapper;

  # ZCode itself rewrites zcode.desktop with the unpacked Electron binary.
  # Own the canonical launcher entry so Noctalia always invokes the FHS
  # wrapper instead of that raw binary.
  xdg.dataFile."applications/zcode.desktop" = {
    source = zcodeDesktop;
    force = true;
  };

  xdg.dataFile."applications/zcode-wrapper.desktop".text = ''
    [Desktop Entry]
    Name=ZCode
    Comment=ZCode Desktop App
    Exec=${config.home.homeDirectory}/.local/bin/zcode %U
    TryExec=${config.home.homeDirectory}/.local/bin/zcode
    NoDisplay=true
    Terminal=false
    Type=Application
    Categories=Development;
    MimeType=x-scheme-handler/zcode;
    StartupWMClass=ZCode
  '';

  xdg.mimeApps.defaultApplications."x-scheme-handler/zcode" = [ "zcode-wrapper.desktop" ];

  # Replace the pre-existing unmanaged mimeapps file from the old AppImage setup.
  xdg.configFile."mimeapps.list".force = true;
}
