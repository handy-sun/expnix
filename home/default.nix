{
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
  PNPM_HOME = data + "/pnpm";
  pnpm_global_bin = PNPM_HOME + "/bin";
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

    inherit
      GOPATH
      CARGO_HOME
      RUSTUP_HOME
      PNPM_HOME
      ;

    # HERMES_HOME = conf + "/hermes";
    UV_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple/";

    NPM_CONFIG_USERCONFIG = conf + "/npmrc";
    CODEX_HOME = conf + "/codex";
    CLAUDE_CONFIG_DIR = conf + "/claude";
    CC_SWITCH_TUI_CONFIG_DIR = conf + "/cc-switch-tui";
    ## eza can find theme
    EZA_CONFIG_DIR = conf + "/eza";
    COLORTERM = "truecolor";

    ## cross-rs: use podman as container engine
    # CROSS_CONTAINER_ENGINE = "podman";
  }
  // myvars.homeEnv
  // lib.optionalAttrs isWSL {
    LD_LIBRARY_PATH = "/usr/lib/wsl/lib:\${LD_LIBRARY_PATH}";
  };

  home.sessionPath = [
    npm_global_bin
    pnpm_global_bin
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
