{
  inputs,
  ...
}:

let
  dotfiles = inputs.my-dotfiles;
  dotconfig = "${dotfiles}/.config";
in
{
  xdg.configFile."alacritty".source = "${dotconfig}/alacritty";
  xdg.configFile."bat".source       = "${dotconfig}/bat";
  xdg.configFile."clangd".source    = "${dotconfig}/clangd";
  xdg.configFile."eza".source       = "${dotconfig}/eza";
  xdg.configFile."go".source        = "${dotconfig}/go";
  xdg.configFile."mpv".source       = "${dotconfig}/mpv";
  xdg.configFile."tmux".source      = "${dotconfig}/tmux";

}

