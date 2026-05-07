{
  lib,
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
        Mod+Shift+T hotkey-overlay-title="Open a Terminal: wezterm" { spawn "wezterm"; }
        Mod+Return { spawn-sh "noctalia-shell ipc call launcher toggle"; }
    }
  '';
  ## Linux Desktop Environments (DEs) typically use XDG Base Directory Specification for configuration and user directories. This setup is not relevant for macOS (Darwin), which has its own conventions. Therefore, we check if the profile level indicates a GUI base and ensure it's not Darwin to determine if we should apply the XDG configuration.
  isLinuxDe = (profileLevel.guiBase && !isDarwin);
in
{
  xdg = {
    configFile = lib.mkIf isLinuxDe {
      "niri/config.kdl".source = userConfig;
      "niri/extra.kdl".source = userExtra;
    };
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
