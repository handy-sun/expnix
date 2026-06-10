{
  lib,
  config,
  inputs,
  isDarwin,
  isHmSingle,
  ...
}:
let
  isNeedBuildEnv = !isDarwin && !isHmSingle;
  nvimConfDir = config.xdg.configHome + "/nvim";
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

}
