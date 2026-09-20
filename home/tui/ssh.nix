{
  lib,
  isDarwin,
  networkingVars,
  ...
}:

{
  home.activation = {
    # https://github.com/nix-community/home-manager/issues/322
    fixSshPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run install -d -m 0700 "$HOME/.ssh"
      if [ -L "$HOME/.ssh/config" ]; then
        src="$(readlink -f "$HOME/.ssh/config")"
        run rm -f "$HOME/.ssh/config"
        run install -m 0600 "$src" "$HOME/.ssh/config"
      fi
    '';
  };

  home.file = {
    # home-manager wrongly thinks it doesn't manage (and thus shouldn't clobber) this file due to the activation script
    ".ssh/config".force = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
      };

      "github.com" = {
        HostName = "ssh.github.com";
        Port = 443;
        User = "git";
        ## Specifies that ssh should only use the identity file explicitly configured above
        ## required to prevent sending default identity files first.
        identitiesOnly = true;
      };
    }
    // networkingVars.ssh.settings;

    includes = [ "~/.ssh/ssh_hosts_extra.conf" ] ++ lib.optionals isDarwin [ "~/.orbstack/ssh/config" ];
  };
}
