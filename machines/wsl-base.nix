{
  pkgs,
  username,
  lib,
  ...
}:
{
  wsl = {
    enable = true;
    defaultUser = "${username}";
    ## Create a desktop shortcut for the nixos-wsl2
    startMenuLaunchers = true;
  };
  # security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "26.05";
  time.timeZone = lib.mkForce "Asia/Shanghai";
}
