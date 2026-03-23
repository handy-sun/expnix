{
  lib,
  isDarwin,
  ...
}:

{
  programs.ssh = {
    enable = !isDarwin;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        compression = true;
        serverAliveInterval = 30;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
      };

      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        ## Specifies that ssh should only use the identity file explicitly configured above
        ## required to prevent sending default identity files first.
        # identitiesOnly = true;
      };
    };

    # includes = [
    #   (lib.mkIf isDarwin "~/.orbstack/ssh/config")
    #   (lib.mkIf isDarwin "~/.ssh/lan_config")
    # ];
  };
}
