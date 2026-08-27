{
  lib,
  pkgs,
  profileLevel,
  isDarwin,
  ...
}:
lib.mkIf profileLevel.guiBase {
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
      profile = "gpu-hq";
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
    };
  };
}
