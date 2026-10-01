## Only the rustdesk part of the reinsvps service set for now; frp / nginx /
## sing-box / mtg / derper / beszel / uptime-kuma stay off until needed.
{
  myvars,
  ...
}:
{
  systemd = {
    tmpfiles.rules = [
      "Z /var/lib/private/rustdesk 0750 rustdesk rustdesk -"
    ];

    ## hbbs drops its key pair under $XDG_CONFIG_HOME, which is unset for
    ## DynamicUser services — point it at the unit's own state directory.
    services.rustdesk-signal.serviceConfig = {
      Environment = [ "XDG_CONFIG_HOME=/var/lib/rustdesk/.config" ];
    };
  };

  services.rustdesk-server = {
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
      relayHosts = [ myvars.txsh011Network.ipv4Address ];
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
}
