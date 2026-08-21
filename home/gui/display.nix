{
  pkgs,
  myutils,
  ...
}:
let
  waykanDisplay = pkgs.writeShellApplication {
    name = "waykan-disp";
    runtimeInputs = [ pkgs.niri ];
    text = builtins.readFile (myutils.relativeToRoot "scripts/waykan-disp.sh");
  };
in
{
  home.packages = [ waykanDisplay ];

  services.kanshi = {
    enable = true;
  };
}
