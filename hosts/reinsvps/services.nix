{
  config,
  lib,
  hostName,
  pkgs,
  myvars,
  myutils,
  ...
}:
let
  hostSecrets = myutils.relativeToRoot "secrets/hosts/${hostName}";
  singBoxSopsFile = hostSecrets + "/sing-box.yaml";
  mtgSopsFile = hostSecrets + "/mtg.yaml";
  inherit (myvars) domain email;
in
{
  imports = [
    (myutils.relativeToRoot "overlays/mtg.nix")
    (myutils.relativeToRoot "modules/mtg")
    (myutils.relativeToRoot "modules/tailscale-derper")
  ];

  environment.systemPackages = [ pkgs.mtg ];

  security.acme.certs.${domain}.reloadServices = [ "tailscale-derper.service" ];
  systemd.services.tailscale-derper = {
    after = [ "acme-${domain}.service" ];
    wants = [ "acme-${domain}.service" ];
  };

  sops = {
    age.keyFile = myvars.sopsAgeKeyFile;

    secrets = {
      sing-box-ss-password = {
        sopsFile = singBoxSopsFile;
        key = "ss_password";
        restartUnits = [ "sing-box.service" ];
      };

      sing-box-vmess-uuid = {
        sopsFile = singBoxSopsFile;
        key = "vmess_uuid";
        restartUnits = [ "sing-box.service" ];
      };

      sing-box-trojan-password = {
        sopsFile = singBoxSopsFile;
        key = "trojan_password";
        restartUnits = [ "sing-box.service" ];
      };

      mtg-bind-to = {
        sopsFile = mtgSopsFile;
        key = "bind_to";
        restartUnits = [ "mtg.service" ];
      };

      mtg-secret = {
        sopsFile = mtgSopsFile;
        key = "secret";
        restartUnits = [ "mtg.service" ];
      };
    };
  };

  systemd = {
    services.proxy-maintenance = {
      description = "Restart mtg and sing-box every two days";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart mtg.service sing-box.service";
      };
    };

    timers.proxy-maintenance = {
      description = "Restart mtg and sing-box every two days";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        ## Monotonic intervals avoid shorter gaps at calendar month boundaries.
        OnBootSec = "2d";
        OnUnitActiveSec = "2d";
        Unit = "proxy-maintenance.service";
      };
    };

    tmpfiles.rules = [
      "Z /var/lib/private/rustdesk 0750 rustdesk rustdesk -"
    ];

    services.rustdesk-signal.serviceConfig = {
      Environment = [ "XDG_CONFIG_HOME=/var/lib/rustdesk/.config" ];
    };
  };

  users.users.sing-box.extraGroups = [
    "nginx"
    "acme"
  ];

  services = {
    tailscale = {
      derperCustom = {
        enable = true;
        openFirewall = true;
        hostname = "hkderp.${domain}";
        certificateDirectory = "/var/lib/acme/${domain}";
        port = 19443;
        stunPort = 3479;
      };

      extraSetFlags = [
        "--relay-server-port=40000"
        "--relay-server-static-endpoints=${myvars.reinsvpsNetwork.ipv4Address}:40000"
      ];
    };

    zerotierone.enable = true;

    sing-box = {
      enable = true;
      settings = {
        log = {
          level = "info";
          timestamp = false;
        };
        inbounds = [
          {
            type = "shadowsocks";
            tag = "ss_29960";
            listen = "::";
            listen_port = 29960;
            method = "2022-blake3-aes-256-gcm";
            password._secret = config.sops.secrets.sing-box-ss-password.path;
          }
          {
            type = "vmess";
            tag = "vmess_29961-kooya";
            listen = "::";
            listen_port = 29961;
            users = [
              {
                uuid._secret = config.sops.secrets.sing-box-vmess-uuid.path;
              }
            ];
          }
          {
            type = "trojan";
            tag = "trojan_29962";
            listen = "::";
            listen_port = 29962;
            users = [
              {
                password._secret = config.sops.secrets.sing-box-trojan-password.path;
              }
            ];
            tls = {
              enabled = true;
              server_name = "tr.${domain}";
              certificate_provider = "trojan-29962-acme";
            };
          }
        ];
        outbounds = [
          {
            type = "direct";
            tag = "direct";
          }
        ];
        certificate_providers = [
          {
            type = "acme";
            tag = "trojan-29962-acme";
            domain = [
              "*.${domain}"
              "${domain}"
            ];
            inherit email;
            dns01_challenge = {
              provider = "cloudflare";
              api_token = {
                _secret = config.sops.secrets.cloudflare-dns-token.path;
              };
            };
          }
        ];
      };
    };

    mtg = {
      enable = true;
      secretFile = config.sops.secrets.mtg-secret.path;
      bindToFile = config.sops.secrets.mtg-bind-to.path;
      settings = {
        concurrency = 8192;
        tcp-buffer = "128kb";
        prefer-ip = "only-ipv4";
        tolerate-time-skewness = "5s";
        domain-fronting.port = 443;
        network = {
          dns = "1.1.1.1";
          timeout = {
            tcp = "5s";
            http = "10s";
            idle = "1m";
          };
        };
        ## Uncomment as needed:
        # defense.anti-replay = { enabled = true; max-size = "1mib"; error-rate = 0.001; };
        # stats.statsd = { enabled = true; address = "127.0.0.1:9833"; metric-prefix = "mtg"; tag-format = "datadog"; };
      };
    };

    rustdesk-server = {
      enable = true;
      ## auto open (TCP 21115-21119, UDP 21116)
      openFirewall = true;

      ## ID server (hbbs)
      signal = {
        enable = true;
        ## ENCRYPTED_ONLY: require encryption
        extraArgs = [
          "-k"
          "_"
        ];
        relayHosts = [ myvars.reinsvpsNetwork.ipv4Address ];
      };

      ## relay server (hbbr)
      relay = {
        enable = true;
        ## also require encryption on relay side
        extraArgs = [
          "-k"
          "_"
        ];
      };
    };

    uptime-kuma = {
      enable = true;
      settings = {
        HOST = "::";
        PORT = "17531";
        UPTIME_KUMA_DB_TYPE = "sqlite";
      };
    };
  };

  users.users.uptime-kuma = {
    isSystemUser = true;
    group = "uptime-kuma";
  };
  users.groups.uptime-kuma = { };

  systemd.services.uptime-kuma.serviceConfig.DynamicUser = lib.mkForce false;
}
