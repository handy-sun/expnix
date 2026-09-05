{
  pkgs,
  lib,
  myutils,
  profileLevel,
  isLinux,
  ...
}:

let
  qqNixPak = myutils.mkNixPakPackage pkgs (myutils.relativeToRoot "packages/nixpaks/qq.nix");
  wechatNixPak = myutils.mkNixPakPackage pkgs (myutils.relativeToRoot "packages/nixpaks/wechat.nix");
  wemeetNixPak = myutils.mkNixPakPackage pkgs (myutils.relativeToRoot "packages/nixpaks/wemeet.nix");
in
lib.mkIf profileLevel.guiHeavy {
  home.packages =
    with pkgs;
    [
      # google-chrome # cannot download .deb from url after some nixpkgs version
      # brave
      feishin
      drawio
    ]
    ++ lib.optionals isLinux [
      mangohud
      qtcreator
      bottles
      qqNixPak
      wechatNixPak
      wemeetNixPak
    ];
}
