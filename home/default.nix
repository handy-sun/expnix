{
  pkgs,
  lib,
  config,
  inputs,
  username,
  myvars,
  homeDir,
  isWSL,
  isDarwin,
  ...
}:
let
  rustupServer = "https://mirrors.tuna.tsinghua.edu.cn/rustup";
  conf = config.xdg.configHome;
  data = config.xdg.dataHome;
  cache = config.xdg.cacheHome;
  CARGO_HOME = data + "/cargo";
  GOPATH = data + "/go";
  RUSTUP_HOME = data + "/rustup";
  cargo_bin = CARGO_HOME + "/bin";
  go_bin = GOPATH + "/bin";
  local_bin = config.home.homeDirectory + "/.local/bin";
  ## npm settings in npmrc
  npm_global_bin = data + "/npm-global/bin";
in
{
  home.stateVersion = "25.11";
  home.username = username;
  home.homeDirectory = homeDir;
  xdg.enable = true;
  programs.home-manager.enable = true;

  home.sessionVariables = {
    LESSHISTFILE = cache + "/less/history";
    LESSKEY = conf + "/less/lesskey";

    inherit GOPATH CARGO_HOME RUSTUP_HOME;

    # HERMES_HOME = conf + "/hermes";
    RUSTUP_DIST_SERVER = rustupServer;
    RUSTUP_UPDATE_ROOT = rustupServer + "/rustup";
    UV_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple/";

    NPM_CONFIG_USERCONFIG = conf + "/npmrc";

    ## eza can find theme
    EZA_CONFIG_DIR = conf + "/eza";
    COLORTERM = "truecolor";

    ## cross-rs: use podman as container engine
    CROSS_CONTAINER_ENGINE = "podman";
  }
  // myvars.homeEnv
  // lib.optionalAttrs isWSL {
    LD_LIBRARY_PATH = "/usr/lib/wsl/lib:\${LD_LIBRARY_PATH}";
  };

  home.sessionPath = [
    npm_global_bin
    cargo_bin
    go_bin
  ]
  ++ (lib.optionals isDarwin [
    local_bin
    "/opt/homebrew/bin"
  ]);

  imports = [
    ./tui
    ./gui
    inputs.my-dotzsh.homeManagerModules.default
    inputs.my-nvimdots.homeManagerModules.default
  ];
}
