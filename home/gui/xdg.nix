{
  config,
  inputs,
  isDarwin,
  profileLevel,
  ...
}:

let
  stateHomeDir = config.xdg.stateHome;
in
{
  xdg = {
    userDirs = {
      enable = (profileLevel.guiBase && !isDarwin);
      createDirectories = true;
      setSessionVariables = false; # 26.05 default: false
      desktop = stateHomeDir + "/Desktop";
      publicShare = stateHomeDir + "/Public";
      templates = stateHomeDir + "/Templates";
      videos = stateHomeDir + "/Videos";
    };
  };
}
