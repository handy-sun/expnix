{
  inputs,
  isDarwin,
  isHmSingle,
  ...
}:
let
  isNeedBuildEnv = (!isDarwin && !isHmSingle);
in
{
  ## donnot use programs.vim
  xdg.configFile = {
    "vim/vimrc".source     = inputs.my-dotvim + "/vimrc";
    "vim/user2.vim".source = inputs.my-dotvim + "/user2.vim";
  };

  programs.neovim.nvimdots = {
    enable = true;
    setBuildEnv = isNeedBuildEnv;  # Only needed for NixOS
    withBuildTools = isNeedBuildEnv; # Only needed for NixOS
  };
}

