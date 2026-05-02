{
  lib,
  pkgs,
  myutils,
  ...
}:

{
  imports = lib.map myutils.relativeToRoot [
    "nixos"
    "modules/niri"
  ];

  hardware.graphics.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  networking.networkmanager.enable = true;
}
