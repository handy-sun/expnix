{
  lib,
  pkgs,
  ...
}:
## system-manager does not declare systemd.defaultPath, but nixpkgs' systemd-lib reads
## config.systemd.defaultPath (and config.systemd.package) # for every service's PATH.
{
  options.systemd.defaultPath = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = with pkgs; [
      coreutils
      findutils
      gnugrep
      gnused
    ];
  };
}
