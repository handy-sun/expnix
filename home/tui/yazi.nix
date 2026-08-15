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
  usesSchemeVfs = lib.versionAtLeast pkgs.yazi.version "26.8.15";
  vfsNameFor = lib.replaceStrings [ "." ] [ "-" ];
  networkServiceNames = map vfsNameFor (lib.attrNames networkingVars.ssh.settings);
  validVfsName =
    name:
    let
      length = builtins.stringLength name;
    in
    length >= 1 && length <= 20 && builtins.match "[a-z0-9-]+" name != null;
  networkSftpServices = lib.mapAttrs' (
    sshName: sshSettings:
    lib.nameValuePair (vfsNameFor sshName) {
      host = sshSettings.HostName;
      user = sshSettings.User;
      port = sshSettings.Port;
      key_file = sshSettings.IdentityFile;
    }
  ) networkingVars.ssh.settings;
  manualSftpServices =
    lib.mapAttrs (_: service: builtins.removeAttrs service [ "type" ]) (manualVfs.services or { })
    // (manualVfs.sftp or { });
  sftpServices = networkSftpServices // manualSftpServices;
  vfsData =
    builtins.removeAttrs manualVfs [
      "services"
      "sftp"
    ]
    // (
      if usesSchemeVfs then
        { sftp = sftpServices; }
      else
        {
          services = lib.mapAttrs (_: service: { type = "sftp"; } // service) sftpServices;
        }
    );
  vfsFile = vfsFormat.generate "vfs.toml" vfsData;
in
assert lib.assertMsg (lib.all validVfsName networkServiceNames)
  "Generated Yazi VFS service names must be 1-20 lowercase letters, digits, or hyphens";
assert lib.assertMsg (
  builtins.length networkServiceNames == builtins.length (lib.unique networkServiceNames)
) "Multiple SSH aliases resolve to the same Yazi VFS service name";
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
