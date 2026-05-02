{
  config,
  lib,
  pkgs,
  ...
}:
let
  conf = config.xdg.configHome;
  niriConf = conf + "/niri";

  userConfig = pkgs.writeText "niri-user-config.kdl" ''
    include "/etc/niri/config.kdl"
    include "${niriConf}/extra.kdl"
  '';
in
{
  home.file = {
    "${niriConf}/config.kdl".source = userConfig;
    "${niriConf}/extra.kdl".source = ./niri-extra.kdl;
  };
}
