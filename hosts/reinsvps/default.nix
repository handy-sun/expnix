{
  lib,
  pkgs,
  myutils,
  ...
}:
let
  sshdPort = 23512;
  frpClientPorts = builtins.genList (x: x + 17580) 31;
  commonProxyPorts = builtins.genList (x: x + 29960) 11;
in
{
  imports =
    (lib.map myutils.relativeToRoot [
      "nixos"
    ])
    ++ (myutils.scanPaths ./.);

  boot.loader.grub.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.networkmanager.enable = true;
  system.stateVersion = "26.05";
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
      11443
      17531
      25465
    ]
    ++ frpClientPorts
    ++ commonProxyPorts;

    allowedUDPPorts = [
      53
      443
      853
      3478
      5201
      9473
      19302
      40000
    ]
    ++ commonProxyPorts;

    ## 6in4 tunnel to HE.net: protocol 41 is neither TCP nor UDP.
    ## The firewall runs the iptables backend, where extraInputRules is inert,
    ## and the chain ends with the final reject, so insert at the head.
    extraCommands = "iptables -w -I nixos-fw 1 -p 41 -j ACCEPT";
  };

  ## Hurricane Electric 6in4 tunnel for IPv6 egress. eth0 only has a private
  ## 10.0.0.0/16 address behind 1:1 NAT, so the tunnel binds the private side
  ## and the NAT rewrites it to the public address registered at HE.
  boot.kernelModules = [ "sit" ];

  systemd.services.he-ipv6 = {
    description = "Hurricane Electric 6in4 tunnel";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.iproute2
      pkgs.gawk
      pkgs.coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ## the DHCP lease may land after network-online; wait for the address
      local_ip=""
      for _ in $(seq 1 30); do
        local_ip=$(ip -4 -o addr show dev eth0 scope global | awk '{print $4}' | cut -d/ -f1)
        [ -n "$local_ip" ] && break
        sleep 1
      done
      if [ -z "$local_ip" ]; then
        echo "he-ipv6: eth0 has no global IPv4 address" >&2
        exit 1
      fi

      ip link del he-ipv6 2>/dev/null || true
      ip tunnel add he-ipv6 mode sit remote 216.218.221.6 local "$local_ip" ttl 255
      ip link set he-ipv6 up mtu 1480
      ip -6 addr replace 2001:470:18:6c7::2/64 dev he-ipv6
      ip -6 route replace default dev he-ipv6
    '';
    preStop = ''
      ip -6 route del default dev he-ipv6 || true
      ip link del he-ipv6 || true
    '';
  };

  ############### Add by reinstall.sh ###############
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
      ## Key-only SSH: no password or keyboard-interactive auth for any
      ## account (qi included). qi's keys come from the central mesh in
      ## lib/networking.nix (userAuthorizedKeysFor), so no lockout.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      MaxSessions = "20";
      TCPKeepAlive = "yes";
    };
  };

  networking = {
    usePredictableInterfaceNames = false;
    interfaces.eth0.useDHCP = true;
  };
  ###################################################
}
