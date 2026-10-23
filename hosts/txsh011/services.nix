## rustdesk plus a standalone derper (txshderp) for the tailnet; beszel agent reports to the reinsvps hub
{
  lib,
  pkgs,
  config,
  inputs,
  myvars,
  myutils,
  ...
}:
let
  inherit (myvars) domain;
  derpHostname = "txshderp.${domain}";
  rustdeskHostname = "rsdesk.${domain}";
  honkSubsSopsFile = myutils.relativeToRoot "secrets/honk-subs.dae";
in
{
  imports = [
    (myutils.relativeToRoot "modules/tailscale-derper")
  ];

  sops = {
    age.keyFile = myvars.sopsAgeKeyFile;
    secrets = {
      cloudflare-dns-token = {
        sopsFile = myutils.relativeToRoot "secrets/cloudflare.yaml";
        key = "token";
      };
      beszel-agent-env = {
        sopsFile = myutils.relativeToRoot "secrets/beszel-agent.env";
        format = "dotenv";
        key = "";
        restartUnits = [ "beszel-agent.service" ];
      };
      honk-subs = {
        sopsFile = honkSubsSopsFile;
        format = "binary";
        restartUnits = [ "honk-core.service" ];
      };
    };
  };

  ## Dedicated cert for the derp hostname only — no wildcard copy on this host.
  security.acme.acceptTerms = true;
  security.acme.certs.${derpHostname} = {
    email = "handy-sun@foxmail.com";
    dnsProvider = "cloudflare";
    domain = derpHostname;
    credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare-dns-token.path;
    ## Same as reinsvps: fixed wait instead of probing authoritative NS over
    ## UDP/53. lego v5 renamed the flag --dns.propagation-wait -> .wait.
    extraLegoFlags = [
      "--dns.propagation.wait"
      "30s"
    ];
    reloadServices = [ "tailscale-derper.service" ];
  };

  environment.etc."honk/honk-config.dae" = {
    source = inputs.my-dotfiles + "/honk-core/honk-config.dae";
    mode = "0600";
  };

  systemd.services.tailscale-derper = {
    after = [ "acme-${derpHostname}.service" ];
    wants = [ "acme-${derpHostname}.service" ];
  };

  services = {
    beszel.agent = {
      enable = true;
      openFirewall = true;
      environmentFile = config.sops.secrets.beszel-agent-env.path;
    };

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

    honk-core = {
      enable = true;
      configFile = "/etc/honk/honk-config.dae";
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
        relayHosts = [ rustdeskHostname ];
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

    iperf3.enable = lib.mkForce false;
  };

  systemd = {
    tmpfiles.rules = [
      "Z /var/lib/private/rustdesk 0750 rustdesk rustdesk -"
    ];
    services.rustdesk-signal.serviceConfig = {
      Environment = [ "XDG_CONFIG_HOME=/var/lib/rustdesk/.config" ];
    };
    services.honk-core = {
      serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/install -Dm0600 ${config.sops.secrets.honk-subs.path} /etc/honk/honk-subs.dae";
    };
  };
}
