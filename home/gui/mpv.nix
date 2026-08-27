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
    scripts = lib.optionals (!isDarwin) [ pkgs.mpvScripts.mpris ];
    config = {
      hwdec = "auto-safe";
      hwdec-codecs = "all";
      sub-auto = "fuzzy";
      audio-file-auto = "fuzzy";
      profile = "gpu-hq";
      log-file = "/tmp/mpv.log";
      volume = 30;
      gpu-shader-cache-dir = "~/.cache/mpv_shaders_cache";
    };
  };
}
