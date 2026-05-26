{ lib, username }:

let
  inherit (lib)
    attrNames
    attrValues
    concatLists
    concatStringsSep
    filterAttrs
    foldl'
    genAttrs
    groupBy
    mapAttrs
    mapAttrsToList
    optional
    unique
    ;

  hasAddresses = host: (host.addresses or { }) != { };

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
    if host ? preferredAddress then host.preferredAddress else builtins.head (attrNames host.addresses);

  preferredAddress = host: host.addresses.${preferredAddressName host};

  preferredTarget = host: if hasAddresses host then addressTarget (preferredAddress host) else null;

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

  sshCommon = host: target: {
    hostname = target;
    user = host.user or username;
    port = host.port or 22;
    checkHostIP = false;
  };

  sshSettingsCommon = host: target: {
    HostName = target;
    User = host.user or username;
    Port = host.port or 22;
    CheckHostIP = false;
  };

  sshBlocksForHost =
    name: host:
    let
      target = preferredTarget host;
      canonicalBlocks =
        if target == null then { } else genAttrs (hostNames name host) (_: sshCommon host target);
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
        if target == null then { } else genAttrs (hostNames name host) (_: sshSettingsCommon host target);
      addressBlocks = foldl' (
        acc: address:
        let
          names = address.names or [ ];
        in
        acc // genAttrs names (_: sshSettingsCommon host (addressTarget address))
      ) { } (attrValues (host.addresses or { }));
    in
    canonicalBlocks // addressBlocks;

  hostDefinitions = {
    orbvmnix = {
      user = username;
      addresses.orb = {
        hostName = "orbvmnix.orb.local";
        names = [ "orbvmnix-orb" ];
      };
      preferredAddress = "orb";
    };

    debnsm = {
      user = username;
      addresses.orb = {
        hostName = "debnsm.orb.local";
        names = [ "debnsm-orb" ];
      };
      preferredAddress = "orb";
    };

    handyMini = {
      user = username;
      aliases = [ "mac" ];
      addresses.orb = {
        hostName = "host.orb.internal";
        names = [
          "handyMini-orb"
          "mac-orb"
        ];
      };
      preferredAddress = "orb";
      sshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuKM3DmTBChkXQOokBv1w8vGr4tsU/bQ1BYqGMyLF+k";
    };

    buking = {
      user = username;
      aliases = [ "handy" ];
      addresses.lan = {
        ipv4 = "192.168.1.27";
        names = [ "buking-lan" ];
      };
      preferredAddress = "lan";
    };

    reinsvps = {
      user = "root";
      port = 23512;
      addresses.private = {
        ipv4 = "10.3.1.9";
        names = [ "reinsvps-private" ];
      };
      preferredAddress = "private";
    };

    nixwsl = {
      user = username;
    };
  };

  hostsFileEntries = concatLists (
    mapAttrsToList (
      name: host:
      let
        preferred = if hasAddresses host then preferredAddress host else { };
        canonicalEntry = optional (preferred ? ipv4) {
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
in
rec {
  userAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH3OY9BaZt4/C5Dxo733g21yHwBb7Id9kRoEZTY6MrF3 replace old id_rsa due to github"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBB7ZnRR8sF38eSwf67aDEeBnL+O74iNDfnQnJ9Qxr6chte2bZv4p9q9nb3LDx1ZRNCGEQmB1k36NFbMrFixCCqs= sunqi@MS-7D17-SQ"
  ];

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
      // {
        "github.com" = {
          hostNames = [
            "github.com"
            "ssh.github.com"
          ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        };
      };

    knownHostsText = concatStringsSep "\n" (
      mapAttrsToList (
        _: value: "${concatStringsSep "," value.hostNames} ${value.publicKey}"
      ) ssh.knownHosts
    );
  };
}
