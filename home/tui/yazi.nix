{
  inputs,
  lib,
  networkingVars,
  pkgs,
  ...
}:

let
  yaziDir = inputs.my-dotfiles + "/.config/yazi";
  yaziPluginsDir = yaziDir + "/plugins";
  vfsFormat = pkgs.formats.toml { };
  manualVfs = builtins.fromTOML (builtins.readFile (yaziDir + "/vfs.toml"));
  networkServices = lib.mapAttrs (_: sshSettings: {
    type = "sftp";
    host = sshSettings.HostName;
    user = sshSettings.User;
    port = sshSettings.Port;
    key_file = sshSettings.IdentityFile;
  }) networkingVars.ssh.settings;
  vfsFile = vfsFormat.generate "vfs.toml" (
    manualVfs
    // {
      services = networkServices // (manualVfs.services or { });
    }
  );
in
{
  programs.yazi = {
    enable = true;
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
    "yazi/vfs.toml".source = vfsFile;
  };
}
