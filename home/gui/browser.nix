{
  lib,
  config,
  profileLevel,
  ...
}:
lib.mkIf profileLevel.guiBase {
  programs.chromium = {
    enable = true;
  };
  programs.firefox = {
    enable = profileLevel.guiHeavy;
    configPath = config.xdg.configHome + "/mozilla/firefox";
  };
}
