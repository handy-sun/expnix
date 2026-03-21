{
  inputs,
  ...
}:

let
  dotfiles = inputs.my-dotfiles;
  dotconfig = "${dotfiles}/.config";
in
{
  imports = [
    inputs.nvimdots.homeManagerModules.default
  ];

  xdg.configFile."alacritty".source = "${dotconfig}/alacritty";
  xdg.configFile."bat".source = "${dotconfig}/bat";
  xdg.configFile."clangd".source = "${dotconfig}/clangd";
  xdg.configFile."eza".source = "${dotconfig}/eza";
  xdg.configFile."git".source = "${dotconfig}/git";
  xdg.configFile."go".source = "${dotconfig}/go";
  xdg.configFile."mpv".source = "${dotconfig}/mpv";
  xdg.configFile."tmux".source = "${dotconfig}/tmux";

  programs.git.ignores = [
    "__pycache__"
    ".DS_Store"
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

}

