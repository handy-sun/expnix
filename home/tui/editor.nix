{
  lib,
  pkgs,
  config,
  inputs,
  isHmSingle,
  ...
}:
let
  inherit (pkgs.stdenv) isDarwin;
  isNeedBuildEnv = !isDarwin && !isHmSingle;
  nvimConfDir = config.xdg.configHome + "/nvim";
  emacsConfDir = inputs.my-dotfiles + "/.emacs.d";
in
{
  home.activation.rmNotNixStoreLink = lib.mkIf config.programs.neovim.nvimdots.enable (
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      test -L "${nvimConfDir}/lua" && {
        realpath "${nvimConfDir}/lua" | xargs -I{} bash -c 'if ! [[ {} =~ "/nix/store" ]]; then
          unlink "${nvimConfDir}/init.lua"
          unlink "${nvimConfDir}/tutor"
          unlink "${nvimConfDir}/snips"
          unlink "${nvimConfDir}/lua"
        fi'
      }
    ''
  );

  ## Use `xdg.configFile."vim/"` instead of programs.vim
  xdg.configFile = {
    "vim/vimrc".source = inputs.my-dotvim + "/vimrc";
    "vim/user2.vim".source = inputs.my-dotvim + "/user2.vim";
  };

  programs.neovim = {
    withRuby = false;
    nvimdots = {
      enable = true;
      bindLazyLock = false;
      setBuildEnv = isNeedBuildEnv; # Only needed for NixOS
      withBuildTools = isNeedBuildEnv; # Only needed for NixOS
    };
  };

  programs.emacs = {
    enable = true;
  };

  home.file.".emacs.d/init.el".source = emacsConfDir + "/init.el";
  home.file.".emacs.d/early-init.el".source = emacsConfDir + "/early-init.el";
  home.file.".emacs.d/conf".source = emacsConfDir + "/conf";

  ## Telega (Emacs Telegram client) runtime deps. telega.el itself is installed
  ## via straight.el/MELPA from the dotfiles config; here we only provide TDLib
  ## plus a toolchain so `M-x telega-server-build` can compile telega-server and
  ## link it (with an rpath) against this exact TDLib. Linux only — on macOS TDLib would come from Homebrew.
  home.packages = lib.optionals (!isDarwin) [
    pkgs.tdlib # libtdjson + headers; telega requires >= 1.8.64
    pkgs.gcc # provides `cc` used by server/Makefile
    pkgs.gnumake
    pkgs.pkg-config # Makefile probes zlib/appindicator via pkg-config
    pkgs.zlib
  ];

  # Consumed by .emacs.d/conf/telega.el to set `telega-server-libs-prefix`.
  home.sessionVariables = lib.mkIf (!isDarwin) {
    TELEGA_TDLIB_PREFIX = "${pkgs.tdlib}";
  };
}
