{
  lib,
  pkgs,
  myvars,
  myutils,
  ...
}:
let
  sshdPort = 23512;
  gateway6Addr = "fe80::feee:ffff:feff:ffff";
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
    interfaces.eth0.ipv6.addresses = [
      {
        address = myvars.txsh011Network.ipv6Address;
        prefixLength = 128;
      }
    ];
    defaultGateway6 = {
      address = gateway6Addr;
      interface = "eth0";
    };
    nameservers = [
      "183.60.83.19"
      "183.60.82.98"
      "2400:3200::1"
      "2402:4e00::"
    ];
  };

  ## The Tencent VPC NDP proxy replies to NS for the gateway link-local with
  ## a valid NA, but this kernel (6.18.x) never installs it — resolution
  ## stays INCOMPLETE and all IPv6 egress fails. Pin the gateway MAC (same
  ## MAC as the IPv4 gateway 10.0.0.1) so the default route resolves without NDP.
  systemd.services.ipv6-gateway-neigh = {
    description = "Pin Tencent VPC IPv6 gateway neighbor entry on eth0";
    after = [ "network-addresses-eth0.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip -6 neigh replace ${gateway6Addr} lladdr fe:ee:7f:99:99:19 dev eth0 nud permanent";
    };
  };
  networking.networkmanager.enable = true;
  ## Fresh host: pin to the release it gets installed with, not reinsvps' 26.05.
  system.stateVersion = "26.11";
  ################ custom ################
  boot.loader.grub.device = "/dev/vda";
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
  ];
  swapDevices = [
    {
      device = "/swapfile";
      size = 1024;
    }
  ];

  networking.firewall = {
    enable = true;
  };

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
      TCPKeepAlive = "yes";
    };
  };

  ###################################################
}
