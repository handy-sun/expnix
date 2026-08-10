{
  pkgs,
  lib,
  profileLevel,
  ...
}:

lib.mkIf profileLevel.guiHeavy {
  home.packages =
    with pkgs;
    [
      # google-chrome # cannot download .deb from url after some nixpkgs version
      # brave
      feishin
      drawio
    ]
    ++ lib.optionals stdenv.isLinux [
      mangohud
    ];
}
