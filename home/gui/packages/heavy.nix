{
  pkgs,
  lib,
  profileLevel,
  ...
}:

lib.mkIf profileLevel.guiHeavy {
  home.packages = with pkgs; [
    # TODO: heavy GUI applications
  ];
}
