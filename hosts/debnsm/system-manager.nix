{
  lib,
  myvars,
  myutils,
  pkgs,
  username,
  ...
}:
let
  commonSystemPackages = myutils.resolveNames pkgs myvars.systemCommonPkgs;
  atticdPort = "8280";
  AbsoluteStateDir = "/var/lib/atticd";
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
      strace
      sysstat
      lm_sensors
      dae
      glider
      iproute2
      iptables
      traceroute
      iputils
    ]);

  services.atticd = {
    enable = true;
    environmentFile = "/etc/atticd.env";
    settings = {
      listen = "0.0.0.0:${atticdPort}";
      database.url = "sqlite://${AbsoluteStateDir}/server.db?mode=rwc";
      storage = {
        type = "local";
        path = "${AbsoluteStateDir}";
      };
    };
  };

  # The client token lives here too; DynamicUser's /var/lib/private directory
  # would prevent the Home Manager user from reaching it.
  users.groups.atticd = { };
  users.users.atticd = {
    isSystemUser = true;
    group = "atticd";
  };
  systemd.services.atticd.serviceConfig = {
    DynamicUser = lib.mkForce false;
    StateDirectoryMode = "0711";
  };

  # home-manager.users.${username}.programs.attic-client.settings = {
  #   default-server = "debnsm";
  #   servers.debnsm = {
  #     endpoint = "http://127.0.0.1:${atticdPort}";
  #     token-file = "${AbsoluteStateDir}/atticd-client.token";
  #   };
  # };

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
  # PVE manages /root/.ssh/authorized_keys as a symlink to /etc/pve/priv/authorized_keys
  # Remove root SSH tmpfiles provisioning to avoid conflict
  systemd.tmpfiles.settings."ssh-root-provision" = lib.mkForce { };

  systemd.services."ssh-system-manager".aliases = lib.mkForce [ ];
}
