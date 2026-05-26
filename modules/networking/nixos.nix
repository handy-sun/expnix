{
  lib,
  username,
  networkingVars,
  ...
}:

{
  networking.hosts = networkingVars.hostsFile;
  networking.search = lib.mkAfter [ "orb.local" ];

  users.users.${username}.openssh.authorizedKeys.keys = networkingVars.userAuthorizedKeys;
}
