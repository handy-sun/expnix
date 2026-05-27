{
  lib,
  isDarwin,
  hostName ? null,
  networkingVars,
  ...
}:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
        UserKnownHostsFile = "~/.ssh/known_hosts";
      };

      "github.com" = {
        HostName = "ssh.github.com";
        Port = 443;
        User = "git";
        ## Specifies that ssh should only use the identity file explicitly configured above
        ## required to prevent sending default identity files first.
        # identitiesOnly = true;
      };
    }
    // networkingVars.ssh.settings;

    includes = lib.optionals isDarwin [ "~/.orbstack/ssh/config" ];
  };

  home.file.".ssh/known_hosts".text = networkingVars.ssh.knownHostsText + "\n";
  home.file.".ssh/authorized_keys".text =
    lib.concatStringsSep "\n" networkingVars.userAuthorizedKeys + "\n";
}
//
  lib.optionalAttrs
    (
      hostName != null
      && networkingVars.hosts ? "${hostName}"
      && networkingVars.hosts."${hostName}" ? sshHostKey
    )
    {
      home.file.".ssh/id_ed25519.pub".text = networkingVars.hosts."${hostName}".sshHostKey + "\n";
    }
