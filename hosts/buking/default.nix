{
  config,
  lib,
  pkgs,
  myvars,
  myutils,
  profileLevel,
  ...
}:

{
  imports =
    lib.map myutils.relativeToRoot (
      [
        "nixos"
      ]
      ++ lib.optionals profileLevel.guiBase [
        "modules/niri"
      ]
    )
    ++ (myutils.scanPaths ./.);

  users.users.${myvars.user} = {
    extraGroups = [
      "wheel"
      "networkmanager"
      ## sunshine (Moonlight host) injects input via /dev/uinput and reads
      ## /dev/input/*; needs both groups or key/mouse events silently fail
      "input"
      "uinput"
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

  boot.tmp.useTmpfs = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = false;
    efiSupport = true;
  };

  sops = {
    defaultSopsFile = myutils.relativeToRoot "secrets/beszel-agent.env";
    defaultSopsFormat = "dotenv";
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.beszel-agent-env = {
      key = "";
      restartUnits = [ "beszel-agent.service" ];
    };
  };

  services = {
    fprintd.enable = true;
    fwupd.enable = true;
    xserver.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PubkeyAuthentication = "yes";
      MaxSessions = "20";
      TCPKeepAlive = "yes";
    };
  };

  services.beszel.agent = {
    enable = true;
    environmentFile = config.sops.secrets.beszel-agent-env.path;
    openFirewall = true;
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.xserver.windowManager.i3.enable = true;

  networking.networkmanager.enable = true;

  system.stateVersion = "26.05";
  ## ------ other optional services ------
  ## replace sddm
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = lib.concatStringsSep " " [
          (lib.getExe pkgs.tuigreet)
          "--time"
          "--remember"
          "--remember-user-session"
          "--asterisks"
          "--kb-sessions 2"
          "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
          "--xsessions ${config.services.displayManager.sessionData.desktops}/share/xsessions"
          "--xsession-wrapper ${pkgs.xinit}/bin/startx"
        ];
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
