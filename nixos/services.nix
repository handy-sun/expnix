{ config, pkgs, ... }:

{
  services = {
    # timesyncd.enable = true; # NTP
    journald.extraConfig = ''
      SystemMaxUse=2G
      RuntimeMaxUse=200M
    '';

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

    # nginx = { 
    #   enable = true;
    #   virtualHosts."localhost" = {
    #     default = true;
    #     root = "/srv/html";
    #   };
    # };

    # zerotierone.enable = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      rootless.enable = true;
    };
  };
}
