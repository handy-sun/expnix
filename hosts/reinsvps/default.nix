{
  lib,
  myutils,
  myvars,
  ...
}:
{
  imports =
    (lib.map myutils.relativeToRoot [
      "nixos"
    ])
    ++ [
      ./hardware-configuration.nix
      ./services.nix
    ];

  boot.loader.grub.enable = true;
  networking.networkmanager.enable = true;

  users.users.${myvars.user} = {
    isSystemUser = true;
    group = "users";
  };

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
      9993
      17531
      17580
      17581
      21115
      21116
      21117
      21118
      21119
      23512
      25465
      29960
      29961
      29962
      29970
    ]; # mtg.local:9833, mtp.proxy:29843
    allowedUDPPorts = [
      53
      443
      853
      3478
      5201
      9473
      19302
      21116
    ];
    extraCommands = ''
      iptables -A INPUT -i lo -j ACCEPT
      iptables -A INPUT -s 127.0.0.0/8 -j ACCEPT
      iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT
      iptables -A INPUT -s 172.16.0.0/12 -j ACCEPT
      iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
      iptables -A INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 1/sec -j ACCEPT
      iptables -A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
      iptables -A INPUT -p icmp -m icmp --icmp-type 3 -j ACCEPT
      iptables -A INPUT -p icmp -m icmp --icmp-type 11 -j ACCEPT
      iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m limit --limit 1/sec --limit-burst 3 -j ACCEPT
      iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j DROP
      iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK RST -m limit --limit 1/sec -j ACCEPT
      iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -m limit --limit 3/min -j LOG --log-prefix "Null scan: "
      iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -m limit --limit 3/min -j LOG --log-prefix "XMAS scan: "
      iptables -A INPUT -p tcp -m state --state NEW -m recent --set --name CONNECTIONS --mask 255.255.255.255 --rsource
      iptables -A INPUT -p tcp -m state --state NEW -m recent --update --seconds 60 --hitcount 10 --name CONNECTIONS --mask 255.255.255.255 --rsource -j DROP

      ip6tables -A INPUT -i lo -j ACCEPT
      ip6tables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
      ip6tables -A INPUT -p icmp -j ACCEPT
      ip6tables -A INPUT -j REJECT --reject-with icmp6-port-unreachable
    '';
  };

  ############### Add by reinstall.sh ###############
  boot.loader.grub.device = "/dev/vda";
  swapDevices = [
    {
      device = "/swapfile";
      size = 512;
    }
  ];
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
  ];
  services.openssh = {
    enable = true;
    ports = [ 23512 ];
    settings = {
      PermitRootLogin = "yes";
      PubkeyAuthentication = "yes";
      MaxSessions = "20";
      TCPKeepAlive = "yes";
    };
  };
  networking = {
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "10.3.1.9";
        prefixLength = 23;
      }
    ];
    defaultGateway = {
      address = "10.3.1.1";
      interface = "eth0";
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "2606:4700:4700::1111"
      "2001:4860:4860::8888"
    ];
  };
  ###################################################
}
