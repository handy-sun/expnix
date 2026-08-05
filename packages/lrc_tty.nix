{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  zig_0_15,
  dbus,
}:

stdenv.mkDerivation {
  pname = "lrc_tty";
  version = "0.6";

  src = fetchFromGitHub {
    owner = "larsgrah";
    repo = "lrc_tty";
    rev = "74335ab3302ba5e1fc8672fa9d1d1b466d63d924";
    hash = "sha256-UMaE0Ke6Izr615BzLqhiFM8A6QDu5SUSXFEotqoMRLk=";
  };

  nativeBuildInputs = [
    pkg-config
    zig_0_15
  ];

  buildInputs = [ dbus ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"
    zig build -Doptimize=ReleaseSafe
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 zig-out/bin/lrc_tty $out/bin/lrc_tty
    runHook postInstall
  '';

  meta = {
    description = "Terminal lyric viewer for MPRIS-compatible players";
    homepage = "https://github.com/larsgrah/lrc_tty";
    license = lib.licenses.gpl3Only;
    mainProgram = "lrc_tty";
    platforms = lib.platforms.linux;
  };
}
