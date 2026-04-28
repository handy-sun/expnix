{
  # pkgs,
  lib,
  myutils,
  ...
}:

{
  imports = (
    lib.map myutils.relativeToRoot [
      "machines/orb-base.nix"
      "nixos"
      "overlays/deno.nix"
    ]
  );

  ## To use some network tools.
  services.resolved.enable = lib.mkForce true;
  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 223.5.5.5
    nameserver 114.114.114.114
    options edns0
    search .
  '';

  services.dae.enable = false;

  services.sing-box = {
    enable = true;
    configGeneration = {
      enable = true;
      sourceUrl = "http://192.168.1.27:3001/c53248f264d9997/download/collection/main?target=V2Ray";
      policyFilter = "@🌐Proxy@⚡UrlTest-~^(?!.*(aote|流量|到期|过滤|官网)).*$@💬AI-~^(?!.*(流量|到期|过滤|官网)).*$@🚀LowLatency-~^(?!.*(流量|到期|过滤|官网)).*$";
      extraArgs = [
        "--log-file"
        ""
        "--icmp"
      ];
    };
  };
  # boot.kernelPackages = pkgs.linuxKernel.packages.linux_7_0;
}
