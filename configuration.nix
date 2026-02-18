# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
  ];

  ############### Add by reinstall.sh ###############
  boot.loader.grub.device = "/dev/vda";
  swapDevices = [{ device = "/swapfile"; size = 512; }];
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];
  services.openssh.enable = true;
  services.openssh.ports = [ 23512 ];
  services.openssh.settings = {
    PermitRootLogin = "yes";
    PubkeyAuthentication = "yes";
    MaxSessions = "20";
    TCPKeepAlive = "yes";
  };
  networking = {
    hostName = "handynixos";
    networkmanager.enable = true;
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "103.149.93.9";
        prefixLength = 23;
      }
    ];
    defaultGateway = {
      address = "103.149.93.1";
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
  ## zsh 
  programs.zsh.enable = true;
  users.users.root = {
    shell = pkgs.zsh;
  };
  ## docker
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  users.users.root.extraGroups = [ "docker" ]; 
  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Open ports in the firewall.
  networking.firewall = { 
    # allowedTCPPorts = [ 22000 23512 ];
    # allowedUDPPorts = [ ... ];
    extraCommands = ''
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 9470:9499 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 17524:17667 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 21115:21119 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 22000 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 23512 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 25465 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 443 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 9470:9499 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 21116 -j ACCEPT
  '';
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  system.stateVersion = "25.11"; # Did you read the comment?
}

