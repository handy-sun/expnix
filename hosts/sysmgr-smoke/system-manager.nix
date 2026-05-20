{
  hostName,
  pkgs,
  username,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    btop
    ripgrep
  ];

  environment.etc."expnix/system-manager-smoke".text = ''
    host = ${hostName}
    user = ${username}
    managed-by = expnix system-manager
  '';
}
