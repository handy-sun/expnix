{
  pkgs,
  lib,
  profileLevel,
  ...
}:

lib.mkIf profileLevel.guiHeavy {
  home.packages = with pkgs; [
    google-chrome
  ];
}
