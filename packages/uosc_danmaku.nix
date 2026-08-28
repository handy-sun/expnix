{
  lib,
  mpvScripts,
  fetchFromGitHub,
  curl,
}:

mpvScripts.buildLua {
  pname = "uosc_danmaku";
  version = "2.1.0";

  ## The upstream repo root is the script itself; deploy it as the
  ## `uosc_danmaku` directory expected by its uosc integration.
  scriptPath = ".";
  passthru.scriptName = "uosc_danmaku";

  src = fetchFromGitHub {
    owner = "Tony15246";
    repo = "uosc_danmaku";
    rev = "e3aeb8a4fe301d903bb39e2e17fbbcf27c6141d1"; # v2.1.0
    hash = "sha256-07J+kNj8wkoLn0bWbER1/xoiT1+60sAziKGivy1/X04=";
  };

  ## The script shells out to curl for all dandanplay API requests.
  runtime-dependencies = [ curl ];

  meta = {
    description = "Danmaku extension for mpv based on the uosc UI framework and the dandanplay API";
    homepage = "https://github.com/Tony15246/uosc_danmaku";
    license = lib.licenses.mit;
  };
}
