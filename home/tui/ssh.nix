{
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

    # includes = [
    #   (lib.mkIf isDarwin "~/.orbstack/ssh/config")
    #   (lib.mkIf isDarwin "~/.ssh/lan_config")
    # ];
  };
}
