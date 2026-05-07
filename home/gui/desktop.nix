{
  lib,
  isDarwin,
  profileLevel,
  ...
}:
lib.mkIf profileLevel.guiBase {
  programs.quickshell.enable = !isDarwin;
}
