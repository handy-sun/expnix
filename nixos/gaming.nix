{
  lib,
  pkgs,
  profileLevel,
  ...
}:

lib.mkIf profileLevel.guiHeavy {
  boot.kernelModules = [ "ntsync" ];

  programs = {
    steam = {
      enable = true;
      protontricks.enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    gamemode.enable = true;
    gamescope.enable = true;
  };
}
