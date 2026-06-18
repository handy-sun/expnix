{
  config,
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
      key = "token";
    };
    frp-web-password = {
      sopsFile = frpSopsFile;
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
    frps = {
      enable = true;
      role = "server";
      environmentFiles = [ config.sops.templates."frp.env".path ];
      settings = {
        bindAddr = "0.0.0.0";
        bindPort = 9473;
        kcpBindPort = 9474;
        quicBindPort = 9475;
        transport.quic = {
          keepalivePeriod = 10;
          maxIdleTimeout = 30;
          maxIncomingStreams = 100000;
        };
        log = {
          to = "/var/log/frps.log";
          level = "info";
          maxDays = 3;
          disablePrintColor = false;
        };
        detailedErrorsToClient = true;
        auth = {
          method = "token";
          token = "{{ .Envs.FRP_TOKEN }}";
        };
        transport.tcpMux = true;
        tcpmuxHTTPConnectPort = 9477;
        tcpmuxPassthrough = true;
        vhostHTTPPort = 9480;
        vhostHTTPSPort = 9483;
        subDomainHost = myvars.domain;
        allowPorts = [
          {
            start = 10001;
            end = 45000;
          }
          { single = 50501; }
        ];
        webServer = {
          addr = "0.0.0.0";
          port = 7500;
          user = "admin";
          password = "{{ .Envs.FRP_WEB_PASSWORD }}";
        };
      };
    };

    frpc = {
      enable = true;
      role = "client";
      environmentFiles = [ config.sops.templates."frp.env".path ];
      settings = {
        user = "vpsLocal";
        serverAddr = "localhost";
        serverPort = 9473;
        auth = {
          method = "token";
          token = "{{ .Envs.FRP_TOKEN }}";
        };
        dnsServer = "223.6.6.6";
        log = {
          to = "/tmp/frpc.log";
          level = "info";
          maxDays = 3;
          disablePrintColor = false;
        };
        loginFailExit = true;
        transport = {
          protocol = "tcp";
          tcpMux = true;
          tls.enable = true;
        };
        proxies = [
          {
            name = "root";
            type = "http";
            customDomains = [ myvars.domain ];
            localPort = 80;
            transport.useCompression = true;
          }
          {
            name = "upku";
            type = "http";
            subdomain = "upku";
            localIP = "127.0.0.1";
            localPort = 80;
            transport.useCompression = true;
          }
          {
            name = "frpweb";
            type = "http";
            subdomain = "frpweb";
            localIP = "127.0.0.1";
            localPort = 7500;
            transport.useCompression = true;
          }
          {
            name = "bes";
            type = "http";
            subdomain = "bes";
            localIP = "127.0.0.1";
            localPort = 80;
            transport.useCompression = true;
          }
        ];
      };
    };
  };
}
