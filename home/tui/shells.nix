{
  config,
  inputs,
  ...
}:

{
  imports = [
    inputs.my-dotzsh.homeManagerModules.default
  ];

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
  };
  programs.dotzsh = {
    enable = true;
    enableSourceZshrc = true;
  };
}
