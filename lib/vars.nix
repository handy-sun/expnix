rec {
  user = "qi";

  langEnv = "zh_CN.UTF-8";

  ## common system enviroment
  commonEnv = {
    LANG = "${langEnv}";
    PAGER = "less";
    LESS = "-RX";
  };

  homeEnv = {
    TERM = "xterm-256color";
    ## for 'sudo -e'
    EDITOR = "nvim";
    VISUAL = "nvim";
    FZF_DEFAULT_COMMAND = "fd --exclude={.git,.idea,.vscode,tags,OrbStack} --type f";
  };

  ## Profile level defaults — hosts can override.
  ## tuibase has no key: always included.
  profileLevel = {
    tuiAdvanced = true;
    tuiOptional = false;
    guiBase = false;
    guiHeavy = false;
  };

  ## Fonts shared across NixOS and darwin.
  ## Attribute name strings — resolved to packages at call sites.
  fontsPkgs = [
    "source-sans"
    ## China, JP, Korea
    "noto-fonts-cjk-sans"
    "noto-fonts-cjk-serif"
    ## suitable
    "fira-code"
    "jetbrains-mono"
    ## icon fonts
    "material-design-icons"
    "font-awesome"
    ## https://github.com/NixOS/nixpkgs/blob/nixos-unstable-small/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
    "nerd-fonts.symbols-only"
    "nerd-fonts.fira-code"
    "nerd-fonts.jetbrains-mono"
    "nerd-fonts.noto"
  ];

  fontFamily = "NotoMono Nerd Font Mono";
}
