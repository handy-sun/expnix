{
  lib,
  config,
  inputs,
  ...
}:

let
  dotfiles = inputs.my-dotfiles;
  dotconfig = "${dotfiles}/.config";
in
{
  xdg.configFile = lib.mkMerge [
    {
      "bat/config".source = "${dotconfig}/bat/config";
      "clangd/config.yaml".source = "${dotconfig}/clangd/config.yaml";
      "eza/theme.yml".source = "${dotconfig}/eza/theme.yml";
      "go/env".source = "${dotconfig}/go/env";
      "php/php-fpm.conf".source = "${dotconfig}/php/php-fpm.conf";
      "pip/pip.conf".source = "${dotconfig}/pip/pip.conf";
      "npmrc".text = ''
        prefix=${config.xdg.dataHome}/npm-global
        cache=${config.xdg.cacheHome}/npm
      '';
    }
  ];
}
