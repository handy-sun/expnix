{
  config,
  hostName,
  myvars,
  myutils,
  ...
}:
let
  frpSopsFile = myutils.relativeToRoot "secrets/hosts/reinsvps/frp.yaml";
in
{
  sops.secrets = {
    frp-token = {
      sopsFile = frpSopsFile;
      format = "yaml";
      key = "token";
    };
    frp-web-password = {
      sopsFile = frpSopsFile;
      format = "yaml";
      key = "web_password";
    };
  };

  # systemd EnvironmentFile — read by root before service start, safe with DynamicUser
  sops.templates."frp.env" = {
    mode = "0400";
    content = ''
      FRP_TOKEN=${config.sops.placeholder.frp-token}
      FRP_WEB_PASSWORD=${config.sops.placeholder.frp-web-password}
    '';
  };

  services.frp.instances = {
    frpc = {
      enable = true;
      role = "client";
      environmentFiles = [ config.sops.templates."frp.env".path ];
      settings = {
        user = hostName;
        serverAddr = myvars.reinsvpsNetwork.ipv4Address;
        serverPort = 9473;
        auth = {
          method = "token";
          token = "{{ .Envs.FRP_TOKEN }}";
        };
        dnsServer = "223.6.6.6";
        log = {
          level = "info";
          maxDays = 3;
          disablePrintColor = false;
        };
        loginFailExit = false;
        transport = {
          protocol = "tcp";
          tcpMux = true;
          tls.enable = true;
        };
        proxies = [
          {
            name = "ssh";
            type = "tcp";
            localPort = 22;
            remotePort = 17590;
            transport.useCompression = true;
          }
        ];
      };
    };
  };
}
