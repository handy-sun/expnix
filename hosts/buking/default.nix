{
  lib,
  pkgs,
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
    ++ (myutils.scanPaths ./.);

  users.users.${myvars.user} = {
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

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
    efiSupport = true;
  };

  services = {
    xserver.enable = true;
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
  services.dae.enable = true;
  services.zerotierone = {
    enable = true;
  };
  ## replace sddm
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --cmd niri-session";
        user = "greeter";
      };
      ## Auto login
      # initial_session = {
      #   command = "niri-session";
      #   user = "${myvars.user}";
      # };
    };
  };
}
