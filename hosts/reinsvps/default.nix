{
  lib,
  pkgs,
  myutils,
  ...
}:
let
  sshdPort = 23512;
  frpClientPorts = builtins.genList (x: x + 17580) 31;
  customPorts = builtins.genList (x: x + 20120) 31;
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
      29960
      29961
      29962
      29970
    ]
    ++ frpClientPorts
    ++ customPorts;

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
    ++ customPorts;

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
