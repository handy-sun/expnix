{
  networkingVars,
  ...
}:

{
  programs.ssh.knownHosts = networkingVars.ssh.knownHosts;
}
