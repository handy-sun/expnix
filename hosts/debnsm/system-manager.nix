{
  lib,
  pkgs,
  myvars,
  myutils,
  ...
}:
let
  commonSystemPackages = myutils.resolveNames pkgs myvars.systemCommonPkgs;
in
{
  ## TODO: check
  # disabledModules = [ "services/networking/sing-box.nix" ];
  # imports = myutils.scanPaths ./. ++ [ (myutils.relativeToRoot "modules/sing-box") ];

  environment.systemPackages =
    commonSystemPackages
    ++ (with pkgs; [
      docker
      zerotierone
      acme-sh
      gcc
      strace
      sysstat
      ethtool
      lm_sensors
      dae
      glider
      iproute2
      iptables
    ]);

  services.beszel.agent = {
    enable = true;
    environmentFile = "/etc/beszel-agent.env";
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  systemd.services."ssh-system-manager".aliases = lib.mkForce [ ];
}
