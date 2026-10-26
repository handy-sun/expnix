{
  lib,
  ...
}:
let
  daeConfig = "/etc/dae/config.dae";
  inherit (lib) mkDefault;

  settings = {
    max-concurrent-downloads = 10;
    max-concurrent-uploads = 10;
  };
in
{
  services = {
    # timesyncd.enable = true; # NTP
    journald.settings.Journal = {
      SystemMaxUse = "2G";
      RuntimeMaxUse = "200M";
    };

    iperf3 = {
      enable = mkDefault true;
      port = 5201;
      ## Omitting --bind makes iperf3 listen on all available interfaces.
      bind = null;
      openFirewall = true;
    };

    dae = {
      enable = mkDefault false;
      openFirewall = {
        enable = true;
        port = 12345;
      };
      configFile = mkDefault daeConfig;
    };

    ## Local resolver. dnsmasq owns 127.0.0.1:53 and /etc/resolv.conf points at
    ## it, while the DHCP upstreams stay in /etc/dnsmasq-resolv.conf thanks to
    ## resolvconf's useLocalResolver mode (so there is no forwarding loop).
    dnsmasq = {
      enable = mkDefault true;
      resolveLocalQueries = true;
      settings = {
        bind-interfaces = true;
        listen-address = [
          "127.0.0.1"
          "::1"
        ];
        ## Tailscale MagicDNS stays authoritative for the tailnet only.
        server = [
          "/ts.net/100.100.100.100"
          "/ts.net/fd7a:115c:a1e0::53"
        ];
      };
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      extraSetFlags = [
        "--accept-routes=false"
        ## dnsmasq is the resolver here; tailscaled must not rewrite resolv.conf.
        "--accept-dns=false"
      ];
    };
  };

  ## Bare tailnet names need the MagicDNS search domain, which would otherwise only arrive with accept-dns.
  networking.resolvconf.extraConfig = lib.mkAfter ''
    search_domains_append='tail62cf95.ts.net'
  '';

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    daemon = { inherit settings; };
  };
}
