{
  appimageTools,
  fetchurl,
  lib,
}:

let
  pname = "helium";
  version = "0.14.4.1";
  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-91hO0NtjUxEZwUyMYe7RD1RfFIelYa8ExzLKRsLaZZo=";
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/helium.desktop \
      $out/share/applications/helium.desktop
    install -m 444 -D ${appimageContents}/helium.png \
      $out/share/icons/hicolor/256x256/apps/helium.png
  '';

  meta = {
    description = "Private, fast, and user-friendly Chromium browser";
    homepage = "https://helium.computer/";
    license = lib.licenses.gpl3Only;
    mainProgram = "helium";
    platforms = [ "x86_64-linux" ];
  };
}
