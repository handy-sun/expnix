{
  pkgs,
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

}
