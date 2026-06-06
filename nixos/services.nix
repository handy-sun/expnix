{
  lib,
  ...
}:
let
  daeConfig = "/etc/dae/config.dae"; # WARN: NOT reproducible
  # daeBin = lib.getExe pkgs.dae;
  inherit (lib) mkDefault;

  settings = {
    registry-mirrors = [
      "https://func.ink"
      "https://lispy.org"
      "https://docker.xiaogenban1993.com"
      "https://docker.mybacc.com"
      "https://docker.yomansunter.com"
      "https://dockerhub.websoft9.com"
    ];
    # bip = "172.17.0.1/16";
    max-concurrent-downloads = 10;
    max-concurrent-uploads = 10;
    # live-restore = true;
  };
in
{
  services = {
    # timesyncd.enable = true; # NTP
    journald.extraConfig = ''
      SystemMaxUse=2G
      RuntimeMaxUse=200M
    '';

    dae = {
      enable = mkDefault false;
      openFirewall = {
        enable = true;
        port = 12345;
      };
      configFile = mkDefault daeConfig;
    };
  };

  # systemd.services.dae.serviceConfig = lib.mkIf config.services.dae.enable {
  #   ExecStart = mkForce [
  #     ""
  #     "${daeBin} run -c ${daeConfig}"
  #   ];
  #   StandardOutput = "append:/var/log/dae.log";
  #   StandardError = "inherit";
  # };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    daemon = { inherit settings; };
  };
}
