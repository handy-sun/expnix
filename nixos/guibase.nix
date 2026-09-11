{
  lib,
  pkgs,
  myvars,
  profileLevel,
  ...
}:

lib.mkIf profileLevel.guiBase {
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
  users.groups.wireshark.members = [ myvars.user ];
}
