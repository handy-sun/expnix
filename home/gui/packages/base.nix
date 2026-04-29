{
  pkgs,
  lib,
  profileLevel,
  ...
}:

lib.mkIf profileLevel.guiBase {
  home.packages = with pkgs; [
    alacritty
    mpv
    # TODO: desktop environment (niri etc.)
  ];
}
