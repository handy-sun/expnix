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
  programs.fish = {
    enable = true;
  };
  programs.dotzsh = {
    enable = true;
    enableSourceZshrc = true;
    enableSourceFishrc = true;
  };
}
