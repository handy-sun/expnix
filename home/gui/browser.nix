{
  lib,
  config,
  profileLevel,
  ...
}:
lib.mkIf profileLevel.guiBase {
  programs.chromium = {
    enable = false;
  };
  programs.firefox = {
    enable = profileLevel.guiHeavy;
    configPath = config.xdg.configHome + "/mozilla/firefox";
  };
}
