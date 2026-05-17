{
  pkgs,
  config,
  profileLevel,
  ...
}:

let
  stateHomeDir = config.xdg.stateHome;
  ## Linux Desktop Environments (DEs) typically use XDG Base Directory Specification for configuration and user directories. This setup is not relevant for macOS (Darwin), which has its own conventions. Therefore, we check if the profile level indicates a GUI base and ensure it's not Darwin to determine if we should apply the XDG configuration.
  isLinuxDe = (profileLevel.guiBase && pkgs.stdenv.isLinux);
in
{
  xdg = {
    userDirs = {
      enable = isLinuxDe;
      createDirectories = true;
      setSessionVariables = false; # 26.05 default: false
      desktop = stateHomeDir + "/Desktop";
      publicShare = stateHomeDir + "/Public";
      templates = stateHomeDir + "/Templates";
      videos = stateHomeDir + "/Videos";
    };
  };
}
