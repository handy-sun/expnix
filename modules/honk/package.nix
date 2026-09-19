{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.0.1.beta.80";
  # musl assets are fully static and embed the eBPF object; digests come from the GitHub release API.
  assets = {
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-musl";
      hash = "sha256-PWWTxT57uSYt+4VKTtlIxK4cbByMnwfRNVMJ9m5XouU=";
    };
    aarch64-linux = {
      suffix = "aarch64-unknown-linux-musl";
      hash = "sha256-ymk/nHRgQhTGToxgvFQ/yuEfrspwG7fOEzBg2BzBWAM=";
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
    url = "https://github.com/daeuniverse/honk/releases/download/v${version}/honk-core-v${version}-${asset.suffix}.tar.gz";
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
