{
  lib,
  pkgs,
  myutils,
  ...
}:
let
  sshdPort = 23512;
in
{
  imports =
    (lib.map myutils.relativeToRoot [
      "nixos"
    ])
    ++ (myutils.scanPaths ./.);

  boot.loader.grub.enable = true;
  boot.kernel.sysctl."net.ipv6.conf.eth0.accept_ra" = false;
  boot.kernel.sysctl."net.ipv6.conf.eth0.autoconf" = false;
  boot.initrd.services.udev.rules = ''
    KERNEL=="vd*[a-z]", ACTION=="add|change", SUBSYSTEM=="block", ATTR{queue/max_sectors_kb}="512"
  '';

  services.udev.extraRules = ''
    KERNEL=="vd*[a-z]", ACTION=="add|change", SUBSYSTEM=="block", ATTR{queue/max_sectors_kb}="512"
  '';
  networking = {
    usePredictableInterfaceNames = false;
    interfaces.eth0.useDHCP = true;
    nameservers = [
      "183.60.83.19"
      "183.60.82.98"
      "2400:3200::1"
      "2402:4e00::"
    ];
  };
  networking.networkmanager.enable = true;
  ## Fresh host: pin to the release it gets installed with, not reinsvps' 26.05.
  system.stateVersion = "26.11";
  ################ custom ################
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      80
      443
      8090
      9473
      9474
      9475
      9476
      9477
      9480
      9483
    ];

    allowedUDPPorts = [
      53
      443
      853
      3478
      5201
    ];

    extraCommands = ''
      iptables -A INPUT -i lo -j ACCEPT
      iptables -A INPUT -s 127.0.0.0/8 -j ACCEPT
      iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
      iptables -A INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 1/sec -j ACCEPT
      iptables -A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
      iptables -A INPUT -p icmp -m icmp --icmp-type 3 -j ACCEPT
      iptables -A INPUT -p icmp -m icmp --icmp-type 11 -j ACCEPT

      iptables -A INPUT -p tcp --dport ${toString sshdPort} -m state --state NEW -m recent --set
      iptables -A INPUT -p tcp --dport ${toString sshdPort} -m state --state NEW -m recent --update --seconds 5 --hitcount 3 -j DROP

      ip6tables -A INPUT -i lo -j ACCEPT
      ip6tables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
      ip6tables -A INPUT -p icmp -j ACCEPT
      ip6tables -A INPUT -j REJECT --reject-with icmp6-port-unreachable
    '';
  };

  ############### Same layout as the reinstall.sh generated VPS ###############
  boot.loader.grub.device = "/dev/vda";
  swapDevices = [
    {
      device = "/swapfile";
      size = 1024;
    }
  ];
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
  ];

  services.openssh = {
    enable = true;
    ports = [ sshdPort ];
    openFirewall = true;
    settings = {
      PermitRootLogin = "yes";
      PubkeyAuthentication = "yes";
      MaxSessions = "20";
      TCPKeepAlive = "yes";
    };
  };

  ###################################################
}
