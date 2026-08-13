{
  lib,
  pkgs,
  profileLevel,
  ...
}:

lib.mkIf (profileLevel.guiBase && pkgs.stdenv.isLinux) {
  services.remmina = {
    enable = true;
    addRdpMimeTypeAssoc = true;
    systemdService.enable = true;
  };
}
