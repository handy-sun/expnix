{
  config,
  profileLevel,
  ...
}:
{
  programs.chromium = {
    enable = false;
  };
  programs.firefox = {
    enable = profileLevel.guiHeavy;
    configPath = config.xdg.configHome + "/mozilla/firefox";
  };
}
