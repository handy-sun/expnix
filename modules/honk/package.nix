{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.1.0-beta.3";
  # musl-full assets are static and include both APIs, the UI and the eBPF object.
  assets = {
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-musl";
      hash = "sha256-EBsfm+2A7/CpKH+7em2bkz8w6Nm1EfrXONSMUBy45Vw=";
    };
    aarch64-linux = {
      suffix = "aarch64-unknown-linux-musl";
      hash = "sha256-m3gsb88llKeK6sMJNx7IAm3PPUYORXVZ6ZLWvZFDHFA=";
    };
  };
  asset =
    assets.${stdenvNoCC.hostPlatform.system}
      or (throw "honk-core ${version}: no prebuilt asset for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "honk-core";
  inherit version;

  src = fetchurl {
    url = "https://github.com/daeuniverse/honk/releases/download/v${version}/honk-core-v${version}-${asset.suffix}-full.tar.gz";
    hash = asset.hash;
  };

  # Tarball layout is upstream-controlled; locate the binary instead of assuming a path.
  installPhase = ''
    runHook preInstall
    binary="$(find . -type f -name honk-core | head -n1)"
    test -n "$binary"
    install -Dm555 "$binary" "$out/bin/honk-core"
    runHook postInstall
  '';

  meta = {
    description = "Rust transparent proxy engine inspired by dae (datapath) and sing-box (outbounds), experimental";
    homepage = "https://github.com/daeuniverse/honk";
    license = lib.licenses.gpl3Only;
    platforms = builtins.attrNames assets;
    mainProgram = "honk-core";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
