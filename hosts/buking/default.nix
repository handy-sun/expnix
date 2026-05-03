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
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  hardware.graphics.enable = true;

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
    device = "/dev/sda";
    efiSupport = true;
  };

  services = {
    xserver.enable = true;
    displayManager.sddm.enable = true;
    # desktopManager.plasma6.enable = true;
  };

  services.openssh = {
    enable = true;
    # settings = {
    #   PermitRootLogin = "yes";
    # };
  };
  networking.networkmanager.enable = true;

  ## ------ other optional services ------
  services.zerotierone = {
    enable = true;
  };
}
