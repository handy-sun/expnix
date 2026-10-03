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

    ## Only ports with actual listeners; service modules (sshd, derper,
    ## rustdesk, iperf3) open their own ports.
    allowedUDPPorts = [ 5201 ];
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
