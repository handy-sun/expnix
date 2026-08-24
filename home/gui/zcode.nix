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
  zcode = pkgs.callPackage (myutils.relativeToRoot "packages/zcode.nix") { };
  zcodeWrapper = pkgs.writeShellScript "zcode" ''
    exec ${zcode}/bin/zcode "$@"
  '';
in
lib.mkIf (profileLevel.guiBase && isLinux) {
  home.packages = [ zcode ];

  home.file.".local/bin/zcode".source = zcodeWrapper;

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
