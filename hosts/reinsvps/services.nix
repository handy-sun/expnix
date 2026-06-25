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
in
{
  imports = [
    (myutils.relativeToRoot "modules/mtg")
  ];

  environment.systemPackages = [ pkgs.mtg ];

  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";

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
    tmpfiles.rules = [
      "Z /var/lib/private/rustdesk 0750 rustdesk rustdesk -"
      # "Z /var/lib/private/uptime-kuma 0750 uptime-kuma uptime-kuma -"
    ];

    services.rustdesk-signal.serviceConfig = {
      # ExecStartPre =
      #   let chown = "${pkgs.coreutils}/bin/chown -R rustdesk:rustdesk /var/lib/rustdesk";
      #   in [ "+${chown}" ];
      Environment = [ "XDG_CONFIG_HOME=/var/lib/rustdesk/.config" ];
    };
  };

  services = {
    sing-box = {
      enable = true;
      settings = {
        log = {
          level = "info";
          timestamp = true;
          output = "/tmp/box-access.log";
        };

        inbounds = [
          {
            type = "shadowsocks";
            tag = "ss-in";
            listen = "::";
            listen_port = 29960;
            method = "2022-blake3-aes-256-gcm";
            password._secret = config.sops.secrets.sing-box-ss-password.path;
          }
          {
            type = "vmess";
            tag = "vmess-in";
            listen = "::";
            listen_port = 29961;
            users = [
              {
                uuid._secret = config.sops.secrets.sing-box-vmess-uuid.path;
              }
            ];
          }
        ];

        outbounds = [
          {
            type = "direct";
            tag = "direct";
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
        extraArgs = [ "-k" "_" ];
        relayHosts = [ myvars.reinsvpsNetwork.ipv4Address ];
      };

      ## relay server (hbbr)
      relay = {
        enable = true;
        ## also require encryption on relay side
        extraArgs = [ "-k" "_" ];
      };
    };

    uptime-kuma = {
      enable = true;
      settings = {
        # HOST = "::"; # default value
        PORT = "17531";
        UPTIME_KUMA_DB_TYPE = "sqlite";
      };
    };
  };

  users.users.uptime-kuma = {
    isSystemUser = true;
    group = "uptime-kuma";
  };
  users.groups.uptime-kuma = {};

  systemd.services.uptime-kuma.serviceConfig.DynamicUser = lib.mkForce false;
}
