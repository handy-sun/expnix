{
  pkgs,
  config,
  inputs,
  myutils,
  homeDir,
  myvars,
  ...
}:
let
  reverseFilter = "~^(?!.*(kooya|流量|套餐|重置)).*$";
  storePathConfig = inputs.sbtpl + "/substore/real-dns-nosniff.json";
  # storePathConfig = pkgs.writeText "real-dns-nosniff.json" (
  #   builtins.readFile (inputs.sbtpl + "/substore/real-dns-nosniff.json")
  # );
  inherit (pkgs.stdenv.hostPlatform) system;
  subsSopsFile = myutils.relativeToRoot "secrets/sb-subs.yaml";
  mihomoSubsSopsFile = myutils.relativeToRoot "secrets/mhm-subs.yaml";
in
{
  disabledModules = [ "services/networking/sing-box.nix" ];
  imports = [
    (myutils.relativeToRoot "modules/mihomo")
    (myutils.relativeToRoot "modules/sing-box")
    (myutils.relativeToRoot "modules/honk")
  ];

  sops.secrets = {
    subs-main = {
      sopsFile = subsSopsFile;
      format = "yaml";
      key = "main";
      restartUnits = [ "sing-box.service" ];
    };

    mihomo-subscription-url = {
      sopsFile = mihomoSubsSopsFile;
      format = "yaml";
      key = "main";
      restartUnits = [ "mihomo.service" ];
    };
  };

  environment.etc."dae/config.dae" = {
    source = inputs.my-dotfiles + "/dae/config-with-singb.dae";
    mode = "0600";
  };

  #  environment.etc."honk/honk-config.dae" = {
  #    source = ./honk-config.dae;
  #    mode = "0600";
  #  };

  services = {
    zerotierone.enable = true;

    sunshine = {
      enable = true;
      openFirewall = true;
      capSysAdmin = true; # required for KMS/DRM screen capture on Wayland (niri)
    };

    dae = {
      enable = true;
      package = inputs.daeuniverse.packages.${system}.dae-unstable;
      configFile = "/etc/dae/config.dae";
    };

    # Trial successor of dae: same TC+dae0 datapath, units conflict so never both at once.
    # To switch over: dae.enable -> false, this enable -> true, rebuild + switch.
    honk-core = {
      enable = true;
      configFile = "/etc/honk/honk-config.dae";
    };

    sing-box = {
      enable = false;
      configGeneration = {
        enable = true;
        sourceUrlFile = config.sops.secrets.subs-main.path;
        policyFilter = "@🌐Proxy@⚡UrlTest-${reverseFilter}@💬AI@🚀LowLatency@🎮Steam";
        extraArgs = [
          "--template"
          "${storePathConfig}"
          "--icmp"
        ];
      };
    };

    mihomo = {
      enable = false;
      subscriptionUrlFile = config.sops.secrets.mihomo-subscription-url.path;
      tunMode = true;
    };
  };

  systemd.services.dae = {
    ## dae's only node is sing-box's mixed inbound (127.0.0.1:2334). Never start it before sing-box is listening: sing-box's ExecStartPre fetches
    ## the subscription and generates config first, which used to make dae's health checks hit a dead port at boot.
    after = [ "sing-box.service" ];
    wants = [ "sing-box.service" ];
  };

  systemd.services.npm-global-update = {
    description = "Update globally installed npm packages";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = myvars.user;
      WorkingDirectory = homeDir;
      Environment = [
        "HOME=${homeDir}"
        "NPM_CONFIG_USERCONFIG=${homeDir}/.config/npmrc"
      ];
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${homeDir}/.cache";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.nodejs}/bin/npm update -g >> ${homeDir}/.cache/npm-updg.log 2>&1'";
      TimeoutStartSec = "20min";
    };
  };

  systemd.timers.npm-global-update = {
    description = "Update globally installed npm packages twice a week";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = [
        "Mon *-*-* 17:00:00"
        "Fri *-*-* 17:00:00"
      ];
      Persistent = true;
      Unit = "npm-global-update.service";
    };
  };
}
