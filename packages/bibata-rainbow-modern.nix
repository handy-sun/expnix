{
  fetchzip,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bibata-rainbow-modern";
  version = "1.1.2";

  src = fetchzip {
    url = "https://github.com/ful1e5/Bibata_Cursor_Rainbow/releases/download/v${finalAttrs.version}/Bibata-Rainbow-Modern.tar.gz";
    hash = "sha256-Ps+IKPwQoRwO9Mqxwc/1nHhdBT2R25IoeHLKe48uHB8=";
  };

  installPhase = ''
    runHook preInstall

    install -d "$out/share/icons/Bibata-Rainbow-Modern"
    cp -r ./* "$out/share/icons/Bibata-Rainbow-Modern/"

    runHook postInstall
  '';

  meta = {
    description = "Semi-animated Bibata cursors with rainbow colors";
    homepage = "https://github.com/ful1e5/Bibata_Cursor_Rainbow";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
})
