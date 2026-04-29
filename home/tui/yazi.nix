{
  inputs,
  pkgs,
  profileLevel,
  ...
}:

let
  yaziDir = inputs.my-dotfiles + "/.config/yazi";
  yaziPluginsDir = yaziDir + "/plugins";
in
{
  programs.yazi = {
    enable = profileLevel.tuiAdvanced;
    shellWrapperName = "yy";
    plugins = {
      inherit (pkgs.yaziPlugins) git ouch sudo;
      ## some local plugins
      yatline = yaziPluginsDir + "/yatline.yazi";
      preview-git = yaziPluginsDir + "/preview-git.yazi";
      fast-enter = yaziPluginsDir + "/fast-enter.yazi";
    };
    flavors = {
      catppuccin-mocha = yaziDir + "/flavors/catppuccin-mocha.yazi";
    };
  };

  xdg.configFile = {
    "yazi/yazi.toml".source = yaziDir + "/yazi.toml";
    "yazi/init.lua".source = yaziDir + "/init.lua";
    "yazi/keymap.toml".source = yaziDir + "/keymap.toml";
    "yazi/theme.toml".source = yaziDir + "/theme.toml";
    ## optional
    "yazi/vfs.toml".source = yaziDir + "/vfs.toml";
  };
}
