{
  lib,
  pkgs,
  myutils,
  profileLevel,
  isLinux,
  ...
}:
let
  waykanDisplay = pkgs.writeShellApplication {
    name = "waykan-disp";
    runtimeInputs = [ pkgs.niri ];
    text = builtins.readFile (myutils.relativeToRoot "scripts/waykan-disp.sh");
  };
in
lib.mkIf (profileLevel.guiBase && isLinux) {
  home.packages = [ waykanDisplay ];

  services.kanshi = {
    enable = true;
  };
}
