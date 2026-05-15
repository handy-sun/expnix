{
  lib,
  myvars,
  myutils,
  ...
}:

{
  imports =
    lib.map myutils.relativeToRoot [
      "nixos"
      "modules/niri"
    ]
    ++ [
      ./hardware-configuration.nix
    ];

  users.users.${myvars.user} = {
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  hardware.graphics.enable = true;
  hardware.bluetooth.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = false;
    device = "/dev/disk/by-uuid/C531-DA7E";
    efiSupport = true;
  };

  services = {
    xserver = {
      enable = true;
    };
    displayManager.sddm.enable = true;
  };

  services.openssh = {
    enable = true;
    # settings = {
    #   PermitRootLogin = "yes";
    # };
  };
  networking = {
    networkmanager.enable = true;
    extraHosts = ''
      192.168.1.27 handy
    '';
  };

  system.stateVersion = "26.05";
  ## ------ other optional services ------
  services.zerotierone = {
    enable = true;
  };
}
