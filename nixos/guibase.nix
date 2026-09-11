{
  lib,
  pkgs,
  inputs,
  myvars,
  myutils,
  profileLevel,
  ...
}:
let
  inherit (inputs.vocotype.packages.${pkgs.stdenv.hostPlatform.system}) vocotype-fcitx5;
in
lib.mkIf profileLevel.guiBase {
  users.groups.wireshark.members = [ myvars.user ];

  programs = {
    wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };

    localsend = {
      enable = true;
      openFirewall = true;
    };
  };

  environment.systemPackages = [
    ## VoCoType settings GUI / CLI (model download, mic, hotkeys)
    vocotype-fcitx5
  ];

  ## Fcitx5 input method for Chinese input on Wayland
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-gtk
        (fcitx5-rime.override {
          rimeDataPkgs = [
            rime-ice
            rime-data
          ];
        })
        ## VoCoType-linux: offline Chinese voice input as a global module. Keep rime as-is;
        ## Models downloaded on first run by `vocotype-settings` into the user cache.
        vocotype-fcitx5
      ];
      candlelightMacosDark.enable = true;
      settings.addons.classicui = {
        globalSection = {
          Font = "Noto Sans CJK SC 16";
          MenuFont = "Noto Sans CJK SC 14";
        };
      };
    };
  };

  fonts = {
    packages = myutils.resolveNames pkgs myvars.fontsPkgs;
    fontconfig = {
      defaultFonts = {
        monospace = [ "Noto Sans Mono CJK SC" ];
        sansSerif = [ "Noto Sans CJK SC" ];
      };
      hinting = {
        enable = true;
        style = "slight";
      };
      antialias = true;
    };
  };
}
