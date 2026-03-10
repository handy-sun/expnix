{ config, pkgs, ... }:

{
  services = {
    timesyncd.enable = true; # NTP

    ## orbstack.nix:  Disable sshd, backup settings
    # openssh = {
    #   enable = false;
    #   ports = [ 22 ];
    #   openFirewall = true;
    #   settings = {
    #     PermitRootLogin = "yes";
    #     PubkeyAuthentication = "yes";
    #     MaxSessions = "20";
    #     TCPKeepAlive = "yes";
    #   };
    # };

    zerotierone.enable = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      rootless.enable = true;
    };
  };
}
