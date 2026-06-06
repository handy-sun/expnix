{
  pkgs,
  inputs,
  myutils,
  ...
}:
let
  template = pkgs.writeText "real-dns.json" (
    builtins.readFile (inputs.sbtpl + "/substore/real-dns.json")
  );
in
{
  disabledModules = [ "services/networking/sing-box.nix" ];
  imports = [ (myutils.relativeToRoot "modules/sing-box") ];

  services = {
    # onedrive.enable = true;
    zerotierone.enable = true;
    dae.enable = true;
    sing-box = {
      enable = true;
      configGeneration = {
        enable = true;
        sourceUrl = "http://handyMini:3001/c53248f264d9997/download/collection/main?target=V2Ray";
        policyFilter = "@🌐Proxy@⚡UrlTest-~^(?!.*(aote|流量|到期|过滤|官网)).*$@💬AI-~^(?!.*(流量|到期|过滤|官网)).*$@🚀LowLatency-~^(?!.*(流量|到期|过滤|官网)).*$";
        extraArgs = [
          "--template"
          "${template}"
          "--icmp"
        ];
      };
    };
  };
}
