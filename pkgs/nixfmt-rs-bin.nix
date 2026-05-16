{
  fetchurl,
  lib,
  stdenvNoCC,
}:

let
  version = "0.4.1";
  assets = {
    aarch64-darwin = {
      name = "nixfmt-aarch64-darwin";
      hash = "sha256-j+irRo/ZdHx1ZEH1DI0PtfJ+dkNkof3qA3Nl5dmn2Vo=";
    };
    aarch64-linux = {
      name = "nixfmt-aarch64-linux";
      hash = "sha256-9nWbqZDTiSMs86DWKEzyKjOo48LLukTXwZNBicUmY2I=";
    };
    x86_64-linux = {
      name = "nixfmt-x86_64-linux";
      hash = "sha256-4JUlWiWkYUlTuK+oPM+EvdyRqkFVzvxzgULo7RgFCDA=";
    };
  };
  system = stdenvNoCC.hostPlatform.system;
  asset = assets.${system} or (throw "nixfmt-rs-bin: no prebuilt binary is available for ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "nixfmt-rs-bin";
  inherit version;

  src = fetchurl {
    url = "https://github.com/Mic92/nixfmt-rs/releases/download/${version}/${asset.name}";
    hash = asset.hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/nixfmt"
    runHook postInstall
  '';

  meta = {
    description = "Prebuilt nixfmt-rs binary installed as nixfmt";
    homepage = "https://github.com/Mic92/nixfmt-rs";
    license = lib.licenses.mpl20;
    mainProgram = "nixfmt";
    platforms = builtins.attrNames assets;
  };
}
