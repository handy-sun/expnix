{
  lib,
  pkgs,
  myvars,
  myutils,
  homeDir,
  ...
}:

{
  imports = lib.map myutils.relativeToRoot [
    "nixos"
    "modules/niri"
  ];

  users.users.${myvars.user} = {
    isNormalUser = true;
    home = homeDir;
    createHome = true;
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

  networking.networkmanager.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
