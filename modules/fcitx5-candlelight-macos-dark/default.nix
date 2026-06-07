{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.i18n.inputMethod.fcitx5.candlelightMacosDark;

  themePackage = pkgs.stdenvNoCC.mkDerivation {
    pname = "fcitx5-candlelight-macos-dark";
    version = "0-unstable-2026-06-07";

    src = pkgs.fetchFromGitHub {
      owner = "thep0y";
      repo = "fcitx5-themes-candlelight";
      rev = "653677b0454569f41c815b3d262a57e42c90ee05";
      hash = "sha256-dN77aUt1qkN177BZOfrT6O72Qp0J2jlM2mGNxI0cBnA=";
    };

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/fcitx5/themes
      cp -r macOS-dark $out/share/fcitx5/themes/

      runHook postInstall
    '';
  };
in
{
  options.i18n.inputMethod.fcitx5.candlelightMacosDark.enable =
    lib.mkEnableOption "the candlelight macOS-dark theme for fcitx5 classicui";

  config = lib.mkIf cfg.enable {
    i18n.inputMethod.fcitx5 = {
      addons = lib.mkAfter [ themePackage ];
      settings.addons.classicui.globalSection.Theme = "macOS-dark";
    };
  };
}
