{
  config,
  hostName,
  pkgs,
  myutils,
  ...
}:
let
  singBoxSopsFile = myutils.relativeToRoot "secrets/hosts/${hostName}/sing-box.yaml";
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
      enable = false; # set to true to activate
      settings = {
        bind-to = "0.0.0.0:11443";
        secret = "00000000000000000000aaaaaaaaaaaaaaaa";
        defense.doppelganger.urls = [
          "https://lalala.com/index.html"
          "https://lalala.com/contacts.html"
        ];
      };
    };

    rustdesk-server = {
      enable = false;
      ## auto open (TCP 21115-21119, UDP 21116)
      openFirewall = true;

      ## enable ID server (hbbs)
      signal = {
        enable = true;
        extraArgs = [ ]; # ex: "-key" force secret
      };

      relay = {
        enable = true;
        extraArgs = [ ];
      };
    };
  };
}
