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

    nativeBuildInputs = [ pkgs.librsvg ];

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
            T=$out/share/fcitx5/themes/mellow-youlan-dark
            # Embed the SVG filter shadow as a 4x bitmap: Qt SVG re-rasterizes
            # feGaussianBlur on every keystroke repaint (upstream issue #6).
            rsvg-convert -w 124 -h 124 $T/panel.svg -o panel-4x.png
            B64=$(base64 -w0 panel-4x.png)
            printf '%s%s%s' \
              '<?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="31" height="31" viewBox="0 0 31 31">
        <image x="0" y="0" width="31" height="31" xlink:href="data:image/png;base64,' \
              "$B64" \
              '"/>
      </svg>
      ' > $T/panel.svg

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
