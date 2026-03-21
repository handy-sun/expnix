{
  inputs,
  pkgs,
  isDarwin,
  isHmSingle,
  ...
}:
let
  isNeedBuildEnv = (!isDarwin && !isHmSingle);
  vimrcStr = builtins.readFile (inputs.my-dotfiles + "/dotvim/init.vim");
in
{
  programs.vim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      vim-airline
      nerdtree
      vim-nerdtree-tabs
      nerdcommenter
      traces-vim
      rainbow
      vim-easy-align
      vim-highlightedyank
      vim-sleuth
      vim-fugitive
      vim-gitgutter
      ack-vim
      clever-f-vim
      a-vim
      vim-cpp-enhanced-highlight
      fzf-wrapper
      indentLine
      vim-smoothie
      blamer-nvim
      tagbar
      ale
      coc-nvim
    ];
    ## load vimrc
    extraConfig = vimrcStr;
  };

  programs.neovim.nvimdots = {
    enable = true;
    setBuildEnv = isNeedBuildEnv;  # Only needed for NixOS
    withBuildTools = isNeedBuildEnv; # Only needed for NixOS
  };
}

