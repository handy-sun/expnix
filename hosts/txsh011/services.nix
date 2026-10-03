## rustdesk plus a standalone derper (txshderp) for the tailnet; frp / nginx /
## sing-box / mtg / beszel / uptime-kuma stay off until needed.
{
  config,
  myvars,
  myutils,
  ...
}:
let
  inherit (myvars) domain;
  derpHostname = "txshderp.${domain}";
in
{
  imports = [
    (myutils.relativeToRoot "modules/tailscale-derper")
  ];

  sops = {
    ## Standalone age key generated on this host (age1kavc... in .sops.yaml);
    age.keyFile = "/var/lib/sops-nix/keys.txt";

    secrets."cloudflare-dns-token" = {
      sopsFile = myutils.relativeToRoot "secrets/cloudflare.yaml";
      key = "token";
    };
  };

  ## Dedicated cert for the derp hostname only — no wildcard copy on this host.
  security.acme.acceptTerms = true;
  security.acme.certs.${derpHostname} = {
    email = "handy-sun@foxmail.com";
    dnsProvider = "cloudflare";
    domain = derpHostname;
    credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets."cloudflare-dns-token".path;
    ## Same as reinsvps: fixed wait instead of probing authoritative NS over
    ## UDP/53. lego v5 renamed the flag --dns.propagation-wait -> .wait.
    extraLegoFlags = [
      "--dns.propagation.wait"
      "30s"
    ];
    reloadServices = [ "tailscale-derper.service" ];
  };

  systemd.services.tailscale-derper = {
    after = [ "acme-${derpHostname}.service" ];
    wants = [ "acme-${derpHostname}.service" ];
  };

  services = {
    tailscale = {
      derperCustom = {
        enable = true;
        openFirewall = true;
        hostname = derpHostname;
        certificateDirectory = "/var/lib/acme/${derpHostname}";
        port = 19443;
        stunPort = 3479;
      };
    };

    rustdesk-server = {
      enable = true;
      ## auto open (TCP 21115-21119, UDP 21116)
      openFirewall = true;
      ## ID server (hbbs)
      signal = {
        enable = true;
        extraArgs = [
          "-k"
          "_"
        ];
        relayHosts = [ myvars.txsh011Network.ipv4Address ];
      };
      ## relay server (hbbr)
      relay = {
        enable = true;
        extraArgs = [
          "-k"
          "_"
        ];
      };
    };
  };

  systemd = {
    tmpfiles.rules = [
      "Z /var/lib/private/rustdesk 0750 rustdesk rustdesk -"
    ];
    services.rustdesk-signal.serviceConfig = {
      Environment = [ "XDG_CONFIG_HOME=/var/lib/rustdesk/.config" ];
    };
  };
}
