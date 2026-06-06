{
  config,
  lib,
  inputs,
  hostName,
  myutils,
  ...
}:

{
  imports = (
    lib.map myutils.relativeToRoot [
      "machines/orb-base.nix"
      "nixos"
    ]
  );

  ## To use some network tools.
  services.resolved.enable = lib.mkForce true;
  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 0.250.250.200
    nameserver 223.5.5.5
    nameserver 114.114.114.114
    options edns0
    search orb.local
  '';

  sops = {
    defaultSopsFile = inputs.my-super + "/hosts/${hostName}/beszel-agent.env";
    defaultSopsFormat = "dotenv";
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.beszel-agent-env = {
      key = "";
    };
  };

  # services.openssh = {
  #   enable = true;
  #   openFirewall = true;
  #   settings = {
  #     PasswordAuthentication = false;
  #     PermitRootLogin = "no";
  #   };
  # };

  services.beszel.agent = {
    enable = true;
    environmentFile = config.sops.secrets.beszel-agent-env.path;
    openFirewall = true;
  };

  ## Mask mounts that are not available in isolated OrbStack containers
  systemd.units."sys-kernel-debug.mount".enable = false;
}
