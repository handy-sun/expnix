{
  config,
  lib,
  pkgs,
  inputs,
  profileLevel,
  isDarwin,
  ...
}:
let
  autoLyrics =
    builtins.replaceStrings
      [
        "@cacheDir@"
        "@curlPath@"
        "@ffprobePath@"
        "@mkdirPath@"
      ]
      [
        "${config.xdg.cacheHome}/mpv/lyrics"
        (lib.getExe pkgs.curl)
        (lib.getExe' pkgs.ffmpeg "ffprobe")
        (lib.getExe' pkgs.coreutils "mkdir")
      ]
      (builtins.readFile "${inputs.my-dotfiles}/.config/mpv/scripts/auto-lyrics.lua");
in
lib.mkIf profileLevel.guiBase {
  xdg.configFile."mpv/scripts/auto-lyrics.lua".text = autoLyrics;

  programs.mpv = {
    enable = true;
    scripts = [
      pkgs.mpvScripts.uosc
      pkgs.mpvScripts.thumbfast
      pkgs.mpvScripts.autoload
    ]
    ++ lib.optionals (!isDarwin) [ pkgs.mpvScripts.mpris ];
    config = {
      hwdec = "auto-safe";
      hwdec-codecs = "all";
      sub-auto = "fuzzy";
      audio-file-auto = "fuzzy";
      profile = "high-quality";
      save-position-on-quit = true;
      deband = true;
      force-window = "immediate";
      log-file = "/tmp/mpv.log";
      volume = 66;
      gpu-shader-cache-dir = "~/.cache/mpv_shaders_cache";
      osc = false;
      osd-font = "Noto Sans CJK SC";
      osd-font-provider = "fontconfig";
      osd-font-size = 24;
      osd-color = "#FFE6E6E6";
      osd-back-color = "#CC1F1F28";
      osd-border-style = "background-box";
      osd-outline-size = 0;
      osd-margin-x = 32;
      osd-margin-y = 24;
      sub-font = "Noto Sans CJK SC";
    };
  };
}
