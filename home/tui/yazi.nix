{
  inputs,
  pkgs,
  ...
}:

let
  dotconfig = "${inputs.my-dotfiles}/.config";
in
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    plugins = {
      inherit (pkgs.yaziPlugins) git;
    };
  };
  xdg.configFile."yazi" = {
    source = "${dotconfig}/yazi";
    recursive = true;
  };
}