{
  pkgs,
  lib,
  config,
  myvars,
  hostName,
  homeDir,
  myutils,
  inputs,
  networkingVars,
  ...
}:
let
  inherit (lib) mkDefault;
  commonSystemPackages = myutils.resolveNames pkgs myvars.systemCommonPkgs;
in
{
  imports = [
    inputs.flyline.nixosModules.default
  ]
  ++ lib.map myutils.relativeToRoot [
    "modules/fcitx5-candlelight-macos-dark"
  ]
  ++ (myutils.scanPaths ./.);

  programs.nix-ld.enable = true;

  environment = {
    localBinInPath = true;
    sessionVariables = myvars.commonEnv // {
      ## For Linux
      SYSTEMD_PAGER = "nvim";
      SYSTEMD_EDITOR = "nvim";
    };

    systemPackages =
      commonSystemPackages
      ++ (with pkgs; [
        docker
        zerotierone
        acme-sh
        gcc
        strace # a diagnostic, debugging and instructional userspace utility for Linux.

        ## system tools
        sysstat
        lm_sensors # for `sensors` command
        e2fsprogs # chattr / lsattr, ext filesystem tools

        ## networking tools
        ethtool
        net-tools
        glider
        iproute2
        iptables
        nftables
        traceroute
      ]);
  };

  networking.hosts = networkingVars.hostsFile;
  # networking.search = lib.mkAfter [ "orb.local" ];
  networking.firewall.enable = mkDefault false;

  programs.ssh = {
    knownHosts = networkingVars.ssh.knownHosts;
    enableAskPassword = mkDefault false;
  };

  programs.zsh.enable = true;
  programs.fish.enable = true;
  programs.bash.enable = true;
  programs.flyline.enable = true;
  services.envfs.enable = true;

  ## MobaXterm monitoring uses non-interactive SSH sessions; keep privileged wrappers first.
  services.openssh.settings.SetEnv = "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin";

  users.defaultUserShell = pkgs.bash;
  users.mutableUsers = false;
  users.users.${myvars.user} = {
    home = homeDir;
    createHome = true;
    group = mkDefault myvars.group;
    hashedPassword = "$6$rgT4Zw3CMO04LwFY$6L5MfeKp9/wsVXHNSylpN3H8xUgEpZmQNM6QIvPk2kSDR2VGxqCUwga8IpaWxYhuuVRY.4uJPlLpWl7hrsjtw0";
    isNormalUser = mkDefault true;
    extraGroups = mkDefault [
      "wheel"
    ];
    openssh.authorizedKeys.keys = networkingVars.userAuthorizedKeysFor hostName;
  };

  users.extraGroups.docker.members = [ "${myvars.user}" ];

  security.sudo.wheelNeedsPassword = false;

  i18n = {
    defaultLocale = mkDefault "${myvars.langEnv}";
    extraLocaleSettings = {
      LC_ALL = mkDefault "${myvars.langEnv}";
    };
  };

  ## Make UTC mode converge, not just flip interpretation: pin /etc/adjtime
  ## against LOCAL leftovers, and rewrite the RTC after the first NTP sync
  ## so the next boot starts correct even if the RTC gets clobbered.
  time = {
    hardwareClockInLocalTime = mkDefault false; # false is UTC; Windows double system set 'true'
    timeZone = lib.mkForce "Asia/Shanghai";
  };

  environment.etc = lib.mkIf (!config.time.hardwareClockInLocalTime) {
    "adjtime".text = ''
      0.0 0 0
      0
      UTC
    '';
  };

  systemd.services.rtc-write-utc = lib.mkIf (!config.time.hardwareClockInLocalTime) {
    description = "Write NTP-synced system time to the hardware clock (UTC)";
    after = [
      "time-sync.target"
      "systemd-time-wait-sync.service"
    ];
    wants = [ "systemd-time-wait-sync.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/hwclock --systohc --utc --noadjfile";
    };
  };

}
