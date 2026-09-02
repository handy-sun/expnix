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

  hardware = {
    graphics = {
      enable = true;
      extraPackages = [
        pkgs.intel-media-driver
      ];
    };
    bluetooth.enable = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  boot.tmp.useTmpfs = true;
  ## Keep the boot console quiet: without `quiet` systemd prints every
  ## "[ OK ] Started ..." status line to the active tty and smears them all
  ## over the ly login screen. Errors still show; journald is unaffected.
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "systemd.show_status=auto"
    "udev.log_level=3"
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = false;
    efiSupport = true;
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

  sops = {
    defaultSopsFile = myutils.relativeToRoot "secrets/beszel-agent.env";
    defaultSopsFormat = "dotenv";
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.beszel-agent-env = {
      key = "";
      restartUnits = [ "beszel-agent.service" ];
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
  ## ly is a standalone TUI display manager. Its NixOS module wires the
  ## generated session directory and xsession wrapper into ly's config:
  ##   .../share/wayland-sessions  (currently niri.desktop)
  ##   .../share/xsessions         (currently none+i3.desktop)
  ## Keep both enabled because this host exposes both Wayland and X11 sessions.
  services.displayManager.ly = {
    enable = true;
    x11Support = true;
    package = pkgs.ly; # TUI -- zig -- https://codeberg.org/AnErrupTion/ly
    settings = {
      ## Persist the selected user and desktop session across logins.
      save = true;
      clock = "%B, %A %d - %H:%M:%S";
      asterisk = "*"; # password masking behavior.
      ## Match tuigreet's explicit session lists: don't add Ly's optional
      ## shell or ~/.xinitrc entries to the chooser.
      shell = false;
      xinitrc = null;

      bg = "0x02000000";
      fg = "0x01FFFFFF";
      error_bg = "0x02000000";
      error_fg = "0x01FF0000";
      # border_fg = "0x01FFFFFF";

      # animation = "colormix"; # "doom", "matrix", "colormix"
      animation_timeout_sec = 300; # 5 minutes
    };
  };
  ## Fix `graphical-session.target` too early issue.
  ## Ref: https://github.com/NixOS/nixpkgs/pull/297434#issuecomment-2348783988
  # systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP = "X-NIXOS-SYSTEMD-AWARE";
}
