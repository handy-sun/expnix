{
  config,
  lib,
  pkgs,
  hostName,
  myvars,
  myutils,
  ...
}:
let
  mountPoint = "/mnt/nuts";
  sopsFile = myutils.relativeToRoot "secrets/hosts/${hostName}/nutstore.yaml";
  rcloneConfig = config.sops.templates."rclone-nutstore.conf".path;
in
{
  sops = {
    secrets.nutstore-rclone-password = {
      inherit sopsFile;
      format = "yaml";
      key = "obscure_pass";
    };
    templates."rclone-nutstore.conf" = {
      owner = myvars.user;
      group = myvars.group;
      mode = "0400";
      restartUnits = [ "rclone-nutstore.service" ];
      content = ''
        [nutstore]
        type = webdav
        url = https://dav.jianguoyun.com/dav/
        vendor = other
        user = 704169722@qq.com
        pass = ${config.sops.placeholder.nutstore-rclone-password}
      '';
    };
  };

  programs.fuse.userAllowOther = true;

  systemd = {
    tmpfiles.rules = [ "d ${mountPoint} 0750 ${myvars.user} users -" ];

    services.rclone-nutstore = {
      description = "Mount Nutstore WebDAV with rclone";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        (builtins.dirOf config.security.wrapperDir)
        pkgs.fuse3
      ];

      unitConfig = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };

      serviceConfig = {
        Type = "notify";
        User = myvars.user;
        Group = myvars.group;
        UMask = "0027";
        CacheDirectory = "rclone-nutstore";
        CacheDirectoryMode = "0750";
        ## free user 600 requests / 30 min，so dir cache set to 1h
        ExecStart = lib.escapeShellArgs [
          (lib.getExe pkgs.rclone)
          "mount"
          "nutstore:"
          mountPoint
          "--config=${rcloneConfig}"
          "--cache-dir=/var/cache/rclone-nutstore"
          "--allow-other"
          "--use-mmap"
          "--dir-cache-time=1h"
          "--poll-interval=0"
          "--tpslimit=3"
          "--tpslimit-burst=6"
          "--vfs-cache-mode=writes"
          "--vfs-cache-max-size=5G"
          "--vfs-cache-max-age=24h"
          "--buffer-size=32M"
          "--vfs-read-chunk-size=4M"
          "--vfs-read-chunk-size-limit=32M"
          "--log-level=INFO"
        ];
        ExecStop = "${config.security.wrapperDir}/fusermount3 -uz ${mountPoint}";
        Restart = "on-failure";
        RestartSec = "30s";
        TimeoutStopSec = "20s";
      };
    };
  };
}
