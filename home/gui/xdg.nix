{
  config,
  pkgs,
  myvars,
  isDarwin,
  profileLevel,
  ...
}:

let
  stateHomeDir = config.xdg.stateHome;
  userConfig = pkgs.writeText "niri-user-${myvars.user}-config.kdl" ''
    include "${pkgs.niri.src}/resources/default-config.kdl"
    include "extra.kdl"
  '';
  userExtra = pkgs.writeText "niri-user-${myvars.user}-extra.kdl" ''
    environment {
      QT_QPA_PLATFORMTHEME "gtk3"
    }
    spawn-at-startup "noctalia-shell"
    prefer-no-csd
    hotkey-overlay {
        skip-at-startup
    }
    binds {
        Mod+Return hotkey-overlay-title="Open a Terminal: wezterm" { spawn "wezterm"; }
        Mod+Space { spawn-sh "qs -c noctalia-shell ipc call launcher toggle"; }
    }
  '';
in
{
  xdg = {
    configFile = {
      "niri/config.kdl".source = userConfig;
      "niri/extra.kdl".source = userExtra;
    };
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
