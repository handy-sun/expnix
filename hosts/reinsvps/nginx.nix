{
  config,
  hostName,
  myvars,
  myutils,
  pkgs,
  ...
}:

let
  inherit (myvars) domain;
in
{
  ## We intentionally proxy the raw client Host header ($http_host) to some
  ## backends. gixy (run by pkgs.writers.writeNginxConfig during config
  ## validation) flags this as [host_spoofing] and fails the build. Wrap gixy
  ## so this single check is skipped while all other checks remain active.
  nixpkgs.overlays = [
    (final: prev: {
      gixy = prev.symlinkJoin {
        name = "gixy-skip-host-spoofing";
        paths = [ prev.gixy ];
        nativeBuildInputs = [ prev.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/gixy --add-flags "--skips host_spoofing"
        '';
        inherit (prev.gixy) meta;
      };
    })
  ];

  services.nginx = {
    enable = true;
    ## replace hand-written worker / sendfile / tcp_nopush / keepalive defaults
    recommendedOptimisation = true;
    ## replace hand-written ssl_protocols / ssl_ciphers / ssl_session_timeout
    recommendedTlsSettings = true;
    ## replace hand-written gzip block
    recommendedGzipSettings = true;
    ## auto add X-Real-IP / X-Forwarded-* / Host proxy headers
    recommendedProxySettings = true;

    eventsConfig = ''
      worker_connections 1024;
      multi_accept on;
    '';

    commonHttpConfig = ''
      types_hash_max_size 3096;
      client_max_body_size 128M;

      log_format main escape=json '$remote_addr [$time_iso8601] "$request" '
                      '$status "$http_user_agent" $body_bytes_sent '
                      '"$http_referer" "$http_x_forwarded_for" $remote_user';
      access_log /var/log/nginx/access.log main;

      real_ip_header proxy_protocol;
    '';

    virtualHosts = {
      "bes.${domain}" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8090";
          extraConfig = ''
            real_ip_header X-Forwarded-For;
            real_ip_recursive on;
            proxy_set_header Host $http_host;
          '';
        };
      };

      "upku.${domain}" = {
        locations."/" = {
          proxyPass = "http://localhost:17531/";
          proxyWebsockets = true;
          extraConfig = ''
            real_ip_header X-Forwarded-For;
            real_ip_recursive on;
            proxy_set_header Host $http_host;
            proxy_read_timeout 86400;
          '';
        };
      };

      "${domain}" = {
        root = "${pkgs.nginx}/html";
        extraConfig = ''
          charset utf-8;
          index index.html;
          error_page 497 https://$http_host$request_uri;
          if ($http_user_agent ~ ^$) { return 403; }
          if ($http_user_agent ~* "Scrapy|python|Nmap|wget|httpclient|MJ12bot|Expanse|ahrefsbot|seznambot|serpstatbot|sindresorhus|zgrab") { return 403; }
        '';
        locations."/" = {
          tryFiles = "$uri $uri/ =404";
        };
        locations."^~ /.*" = {
          extraConfig = "deny all;";
        };
        locations."= /404.html" = {
          extraConfig = "internal;";
        };
        locations."= /50x.html" = {
          extraConfig = "internal;";
        };
      };

      "*.${domain}" = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/" = {
          proxyPass = "http://127.0.0.1:9480";
          extraConfig = ''
            error_page 502 http://$host:9480$request_uri;
          '';
        };
      };
    };
  };

  sops.secrets."cloudflare-dns-token" = {
    sopsFile = myutils.relativeToRoot "secrets/hosts/${hostName}/cloudflare.yaml";
    key = "token";
  };

  security.acme.acceptTerms = true;
  security.acme.certs.${domain} = {
    group = "nginx";
    email = "handy-sun@foxmail.com";
    dnsProvider = "cloudflare";
    domain = domain;
    extraDomainNames = [ "*.${domain}" ];
    credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets."cloudflare-dns-token".path;
  };
}
