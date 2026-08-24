{
  appimageTools,
  fetchurl,
  lib,
  desktopFile ? null,
  desktopFilePath ? null,
}:

let
  pname = "zcode";
  version = "3.8.1";
  src = fetchurl {
    url = "https://cdn-zcode.z.ai/zcode/electron/releases/${version}/linux-x64/ZCode-${version}-linux-x64.AppImage";
    hash = "sha256-tCDepQlht31cdbCLkk2kGrUpxyCn7DLqy+labYQxmeA=";
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # ZCode rewrites its user-level desktop entry to process.execPath on every
  # launch.  Keep that file read-only inside the FHS container so it cannot
  # replace the stable wrapper command used by desktop launchers.
  extraBwrapArgs = lib.optional (desktopFile != null && desktopFilePath != null) ''
    --ro-bind ${desktopFile} ${desktopFilePath}
  '';

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/zcode.desktop \
      $out/share/applications/zcode.desktop
    substituteInPlace $out/share/applications/zcode.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=zcode --no-sandbox %U'
    install -m 444 -D ${appimageContents}/zcode.png \
      $out/share/icons/hicolor/512x512/apps/zcode.png
  '';

  meta = {
    description = "ZCode Desktop App";
    homepage = "https://zcode.z.ai/";
    license = lib.licenses.unfree;
    mainProgram = "zcode";
    platforms = [ "x86_64-linux" ];
  };
}
