{
  hostName,
  pkgs,
  username,
  ...
}:

{
  services.beszel.agent = {
    enable = true;
    environmentFile = "/etc/beszel-agent.env";
  };

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
