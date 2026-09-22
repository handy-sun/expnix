{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.i18n.inputMethod.fcitx5.mellowYoulanDark;

  themePackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "fcitx5-mellow-youlan-dark";
    version = "0-unstable-2026-05-30";

    src = pkgs.fetchFromGitHub {
      owner = "sanweiya";
      repo = "fcitx5-mellow-themes";
      rev = "2c93b0ea3418a55c03f526d963c84a7ccde2c1e9";
      hash = "sha256-y7Q7BgObG99l0+8UVn24TibmUK3Xdq+/1N/G4o9eYAY=";
    };

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/fcitx5/themes
      cp -r mellow-youlan-dark $out/share/fcitx5/themes/

      runHook postInstall
    '';
  };
in
{
  options.i18n.inputMethod.fcitx5.mellowYoulanDark.enable =
    lib.mkEnableOption "the mellow youlan dark theme for fcitx5 classicui";

  config = lib.mkIf cfg.enable {
    i18n.inputMethod.fcitx5 = {
      addons = lib.mkAfter [ themePackage ];
      settings.addons.classicui.globalSection.Theme = "mellow-youlan-dark";
    };
  };
}
