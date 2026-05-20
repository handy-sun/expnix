{
  lib,
  config,
  inputs,
  profileLevel,
  ...
}:

let
  dotfiles = inputs.my-dotfiles;
  dotconfig = "${dotfiles}/.config";
  helixConfig = "${dotconfig}/helix";
in
{
  xdg.configFile = lib.mkMerge [
    {
      "bat/config".source = "${dotconfig}/bat/config";
      "clangd/config.yaml".source = "${dotconfig}/clangd/config.yaml";
      "eza/theme.yml".source = "${dotconfig}/eza/theme.yml";
      "go/env".source = "${dotconfig}/go/env";
      "mpv/mpv.conf".source = "${dotconfig}/mpv/mpv.conf";
      "php/php-fpm.conf".source = "${dotconfig}/php/php-fpm.conf";
      "pip/pip.conf".source = "${dotconfig}/pip/pip.conf";
      "npmrc".text = ''
        prefix=${config.xdg.dataHome}/npm-global
      '';
    }
    (lib.mkIf profileLevel.tuiOptional {
      "helix/config.toml".source = "${helixConfig}/config.toml";
      "helix/init.scm".source = "${helixConfig}/init.scm";
      "helix/helix.scm".source = "${helixConfig}/helix.scm";
      "helix/languages.toml".source = "${helixConfig}/languages.toml";
      # "helix/lsp-ai.json".source = "${helixConfig}/lsp-ai.json";
      ## directories
      "helix/actions".source = "${helixConfig}/actions";
      "helix/runtime".source = "${helixConfig}/runtime";
      "helix/snippets".source = "${helixConfig}/snippets";
      "helix/themes".source = "${helixConfig}/themes";
      "helix/tutors".source = "${helixConfig}/tutors";
    })
  ];
}
