## btrfs snapshot + scrub for the single-NVMe Ubuntu-style layout (@ @home @nix @swap).
## snapper covers what NixOS generations cannot: mutable state in @ (/var, /etc)
## and user data in @home. Same-disk snapshots are not a backup against disk loss.
{
  lib,
  pkgs,
  ...
}:
{
  services.snapper = {
    ## Fire a missed snapshot window on boot instead of skipping it.
    persistentTimer = true;
    configs = {
      root = {
        SUBVOLUME = "/";
        FSTYPE = "btrfs";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 5;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 3;
      };
      home = {
        SUBVOLUME = "/home";
        FSTYPE = "btrfs";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 3;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 3;
      };
    };
    ## @nix is skipped on purpose: the store is immutable and snapshots would
    ## pin extents against nix GC.
  };

  ## The NixOS module only writes /etc/snapper/configs; it never runs
  ## `snapper create-config`, so the .snapshots subvolumes are on us.
  systemd.services.snapper-bootstrap = {
    description = "Create snapper .snapshots subvolumes if missing";
    after = [ "local-fs.target" ];
    before = [
      "snapper-timeline.service"
      "snapper-cleanup.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "snapper-bootstrap" ''
        for d in /.snapshots /home/.snapshots; do
          if [ ! -e "$d" ]; then
            ${lib.getExe' pkgs.btrfs-progs "btrfs"} subvolume create "$d"
          fi
        done
      '';
    };
  };

  ## Silent corruption repair. fileSystems defaults to every btrfs mount point,
  ## which would scrub the same device four times (/ /nix /home /swap share it).
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  environment.systemPackages = [ pkgs.btrfs-assistant ];
}
