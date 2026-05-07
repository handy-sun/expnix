{
  pkgs,
  lib,
  config,
  isHeLinux,
  ...
}:
let
  daeConfig = "/etc/dae/config.dae"; # WARN: NOT reproducible
  daeBin = lib.getExe pkgs.dae;
in
{
  services = {
    # timesyncd.enable = true; # NTP
    journald.extraConfig = ''
      SystemMaxUse=2G
      RuntimeMaxUse=200M
    '';

    dae = {
      enable = lib.mkDefault isHeLinux;
      openFirewall = {
        enable = true;
        port = 12345;
      };
      configFile = daeConfig;
    };

    sing-box = {
      enable = lib.mkDefault true;
      configGeneration = {
        enable = true;
        sourceUrl = "http://handy:3001/c53248f264d9997/download/collection/main?target=V2Ray";
        policyFilter = "@🌐Proxy@⚡UrlTest-~^(?!.*(aote|流量|到期|过滤|官网)).*$@💬AI-~^(?!.*(流量|到期|过滤|官网)).*$@🚀LowLatency-~^(?!.*(流量|到期|过滤|官网)).*$";
        extraArgs = [
          "--log-file"
          ""
          "--icmp"
        ];
      };
    };
  };

  systemd.services.dae.serviceConfig =
    if config.services.dae.enable then
      {
        ExecStart = lib.mkForce [
          ""
          "${daeBin} run -c ${daeConfig}"
        ];
        StandardOutput = "append:/var/log/dae.log";
        StandardError = "inherit";
      }
    else
      { };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    rootless = {
      enable = true;
      daemon.settings = {
        registry-mirrors = [
          "https://atomhub.openatom.cn"
          "https://docker.zhai.cm"
          "https://a.ussh.net"
          "https://hub.littlediary.cn"
          "https://hub.rat.dev"
          "https://docker.m.daocloud.io"
          "https://docker.1ms.run"
          "https://dytt.online"
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
        log-opts = {
          max-size = "4m";
          max-file = "3";
        };
        # live-restore = true;
      };
    };
  };
}
