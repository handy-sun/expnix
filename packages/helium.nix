{
  appimageTools,
  fetchurl,
  lib,
}:

let
  pname = "helium";
  version = "0.17.1.1";
  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-E0A+DPNLWJer96udmZ7kHt8v1YSmCBNLpmFUrvUOeI8=";
  };
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # VA-API: Chromium dlopens libva at runtime; without it in the FHS env
  # hardware decode silently falls back to ffmpeg software decoding
  # (~1 core pegged, high temps, loud fan). The iHD driver itself is found
  # via the standard /run/opengl-driver path (hardware.graphics.extraPackages).
  extraPkgs =
    pkgs: with pkgs; [
      libva
      libva-utils # vainfo, for verifying the stack inside the env
    ];

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/helium.desktop \
      $out/share/applications/helium.desktop
    install -m 444 -D ${appimageContents}/helium.png \
      $out/share/icons/hicolor/256x256/apps/helium.png
    # Enable VA-API video decode (GL compositing path) explicitly instead
    # of relying on upstream defaults.
    sed -i 's/^Exec=helium/Exec=helium --enable-features=VaapiVideoDecodeLinuxGL/' \
      $out/share/applications/helium.desktop
  '';

  meta = {
    description = "Private, fast, and user-friendly Chromium browser";
    homepage = "https://helium.computer/";
    license = lib.licenses.gpl3Only;
    mainProgram = "helium";
    platforms = [ "x86_64-linux" ];
  };
}
