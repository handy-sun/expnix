{ lib, username }:

let
  inherit (lib)
    attrNames
    attrValues
    concatLists
    concatStringsSep
    filterAttrs
    foldl'
    hasInfix
    optionalAttrs
    genAttrs
    groupBy
    mapAttrs
    mapAttrsToList
    optional
    unique
    ;

  # hasAddresses = host: (host.addresses or { }) != { };

  addressAttrNames = host: attrNames (host.addresses or { });

  hasSingleAddress = host: builtins.length (addressAttrNames host) == 1;

  addressTarget =
    address:
    if address ? hostName then
      address.hostName
    else if address ? ipv4 then
      address.ipv4
    else
      address.ipv6;

  preferredAddressName =
    host:
    if host ? preferredAddress then
      host.preferredAddress
    else if hasSingleAddress host then
      builtins.head (addressAttrNames host)
    else
      null;

  preferredAddress =
    host:
    let
      name = preferredAddressName host;
    in
    if name != null then host.addresses.${name} else null;

  preferredTarget =
    host:
    let
      address = preferredAddress host;
    in
    if address != null then addressTarget address else null;

  useCanonicalName = host: (host.useCanonicalName or false) || hasSingleAddress host;

  hostNames = name: host: unique ([ name ] ++ (host.aliases or [ ]));

  addressNames =
    host:
    unique (
      concatLists (
        map (
          address:
          (address.names or [ ])
          ++ optional (address ? hostName) address.hostName
          ++ optional (address ? ipv4) address.ipv4
          ++ optional (address ? ipv6) address.ipv6
        ) (attrValues (host.addresses or { }))
      )
    );

  knownHostNames = name: host: unique ((hostNames name host) ++ (addressNames host));

  sshCommon =
    host: target:
    {
      hostname = target;
      user = host.user or username;
      port = host.port or 22;
      identityFile = "~/.ssh/id_ed25519";
    }
    // optionalAttrs (hasInfix "orb.local" target) {
      checkHostIP = false;
    };

  sshSettingsCommon =
    host: target:
    {
      HostName = target;
      User = host.user or username;
      Port = host.port or 22;
      IdentityFile = "~/.ssh/id_ed25519";
    }
    // optionalAttrs (hasInfix "orb.local" target) {
      CheckHostIP = false;
    };

  sshBlocksForHost =
    name: host:
    let
      target = preferredTarget host;
      canonicalBlocks =
        if target != null && useCanonicalName host then
          genAttrs (hostNames name host) (_: sshCommon host target)
        else
          { };
      addressBlocks = foldl' (
        acc: address:
        let
          names = address.names or [ ];
        in
        acc // genAttrs names (_: sshCommon host (addressTarget address))
      ) { } (attrValues (host.addresses or { }));
    in
    canonicalBlocks // addressBlocks;

  sshSettingsForHost =
    name: host:
    let
      target = preferredTarget host;
      canonicalBlocks =
        if target != null && useCanonicalName host then
          genAttrs (hostNames name host) (_: sshSettingsCommon host target)
        else
          { };
      addressBlocks = foldl' (
        acc: address:
        let
          names = address.names or [ ];
        in
        acc // genAttrs names (_: sshSettingsCommon host (addressTarget address))
      ) { } (attrValues (host.addresses or { }));
    in
    canonicalBlocks // addressBlocks;

  ## All hosts ssh keys should be added to known_hosts to prevent ssh asking for confirmation when connecting for the first time, which is especially important for hosts with dynamic IPs. However, we still want to have github.com in known_hosts to prevent MITM attack, so we add it manually here.
  hostDefinitions = {
    orbvmnix = {
      user = username;
      addresses.orb = {
        hostName = "orbvmnix.orb.local";
      };
      sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIERWaYmUBGmyw6unmj+fOd55jkFL3o/kfAJFw2WZ/i+8 qi@orbvmnix";
    };

    handyMini = {
      user = username;
      addresses.ethernet = {
        ipv4 = "192.168.1.27";
      };
      sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDXv7vJ9dWH6CY/xKzB6qjpWCcTlhxI17BHn8/g+zI9x qi@handyMini";
    };

    buking = {
      user = username;
      addresses.ethernet = {
        ipv4 = "192.168.1.58";
      };
      sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMizFfVaUfb6gY10IXqG7dguFa3P5Z8OwLiU8n4Q+SvG qi@buking";
    };

    reinsvps = {
      user = username;
      port = 23512;
      addresses.common = {
        ipv4 = "10.3.1.9";
      };
    };

    nixwsl = {
      user = username;
      sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA4enUIMLYr8hinZIAy8NM7uqtwAJO8Ts1H/pB0h9b+S qi@nixwsl";
    };

    ms7d = {
      addresses.eth = {
        ipv4 = "192.168.1.29";
      };
      sshHostKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBB7ZnRR8sF38eSwf67aDEeBnL+O74iNDfnQnJ9Qxr6chte2bZv4p9q9nb3LDx1ZRNCGEQmB1k36NFbMrFixCCqs= sunqi@MS-7D17-SQ";
    };
  };

  hostsFileEntries = concatLists (
    mapAttrsToList (
      name: host:
      let
        preferred = preferredAddress host;
        canonicalEntry = optional (preferred != null && preferred ? ipv4) {
          ip = preferred.ipv4;
          names = hostNames name host;
        };
        addressEntries = concatLists (
          map (
            address:
            optional (address ? ipv4 && (address.names or [ ]) != [ ]) {
              ip = address.ipv4;
              names = address.names;
            }
          ) (attrValues (host.addresses or { }))
        );
      in
      canonicalEntry ++ addressEntries
    ) hostDefinitions
  );

  groupedHostsFileEntries = groupBy (entry: entry.ip) hostsFileEntries;

  externalKnownHosts = {
    "github.com" = {
      hostNames = [
        "github.com"
        "ssh.github.com"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
    "codeberg.org" = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVIC02vnjFyL+I4RHfvIGNtOgJMe769VTF1VR4EB3ZB";
    };
  };

  extraUserAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH3OY9BaZt4/C5Dxo733g21yHwBb7Id9kRoEZTY6MrF3 replace-old-id_rsa"
  ];

  sshHostAuthorizedKeysFor =
    localHostName:
    mapAttrsToList (_: host: host.sshHostKey) (
      filterAttrs (name: host: host ? sshHostKey && name != localHostName) hostDefinitions
    );
in
rec {
  userAuthorizedKeysFor =
    localHostName: unique (extraUserAuthorizedKeys ++ sshHostAuthorizedKeysFor localHostName);

  userAuthorizedKeys = userAuthorizedKeysFor null;

  hosts = hostDefinitions;

  hostsFile = mapAttrs (
    _: entries: unique (concatLists (map (entry: entry.names) entries))
  ) groupedHostsFileEntries;

  hostsText = concatStringsSep "\n" (
    mapAttrsToList (ip: names: "${ip} ${concatStringsSep " " names}") hostsFile
  );

  ssh = {
    matchBlocks = foldl' (acc: name: acc // sshBlocksForHost name hosts.${name}) { } (attrNames hosts);

    settings = foldl' (acc: name: acc // sshSettingsForHost name hosts.${name}) { } (attrNames hosts);

    knownHosts =
      (mapAttrs (name: host: {
        hostNames = knownHostNames name host;
        publicKey = host.sshHostKey;
      }) (filterAttrs (_: host: host ? sshHostKey) hosts))
      // externalKnownHosts;

    knownHostsText = concatStringsSep "\n" (
      mapAttrsToList (
        _: value: "${concatStringsSep "," value.hostNames} ${value.publicKey}"
      ) ssh.knownHosts
    );
  };
}
