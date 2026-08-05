{
  config,
  lib,
  pkgs,
  myvars,
  myutils,
  ...
}:
let
  mountPoint = "/mnt/opls";
  openlistSecrets = myutils.relativeToRoot "secrets/hosts/buking/openlist.yaml";
  rcloneConfig = config.sops.templates."rclone-openlist.conf".path;
in
{
  sops = {
    secrets.openlist-rclone-password = {
      sopsFile = openlistSecrets;
      format = "yaml";
      key = "rclone_password";
    };

    templates."rclone-openlist.conf" = {
      owner = myvars.user;
      group = myvars.group;
      mode = "0400";
      restartUnits = [ "rclone-openlist.service" ];
      content = ''
        [opls]
        type = webdav
        url = http://fngo:5244/dav/
        vendor = other
        user = buking-opls
        pass = ${config.sops.placeholder.openlist-rclone-password}
      '';
    };
  };

  programs.fuse.userAllowOther = true;

  systemd = {
    tmpfiles.rules = [ "d ${mountPoint} 0750 ${myvars.user} users -" ];

    services.rclone-openlist = {
      description = "Mount fngo OpenList with rclone";
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
        CacheDirectory = "rclone-openlist";
        CacheDirectoryMode = "0750";
        ExecStart = lib.escapeShellArgs [
          (lib.getExe pkgs.rclone)
          "mount"
          "opls:"
          mountPoint
          "--config=${rcloneConfig}"
          "--cache-dir=/var/cache/rclone-openlist"
          "--allow-other"
          "--use-mmap"
          "--dir-cache-time=2m"
          "--vfs-cache-mode=writes"
          "--vfs-cache-max-size=10G"
          "--buffer-size=512M"
          "--vfs-read-chunk-size=16M"
          "--vfs-read-chunk-size-limit=64M"
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
