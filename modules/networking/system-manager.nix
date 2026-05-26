{
  hostName,
  username,
  networkingVars,
  ...
}:

{
  environment.etc."hosts" = {
    text = ''
      127.0.0.1 localhost
      ::1 localhost ip6-localhost ip6-loopback
      127.0.1.1 ${hostName}

      # expnix managed hosts
      ${networkingVars.hostsText}
    '';
    replaceExisting = true;
  };

  environment.etc."ssh/ssh_known_hosts".text = networkingVars.ssh.knownHostsText;
  users.users.${username}.openssh.authorizedKeys.keys = networkingVars.userAuthorizedKeys;
}
