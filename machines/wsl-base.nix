{
  username,
  ...
}:
{
  wsl = {
    enable = true;
    defaultUser = "${username}";
    ## Create a desktop shortcut for the nixos-wsl2
    startMenuLaunchers = true;
  };

  system.stateVersion = "26.05";
}
