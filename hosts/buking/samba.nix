{
  hostName,
  myvars,
  homeDir,
  ...
}:
{
  ## SMB server; first share is qi's home, add more under
  ## services.samba.settings when needed.
  ## Auth uses Samba's own passdb, so after `just switch` run once:
  ##   sudo smbpasswd -a qi
  services = {
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          security = "user";
          "server string" = hostName;
          "server min protocol" = "SMB2"; # SMB2+ only, drop legacy SMB1
        };
        ${myvars.user} = {
          path = homeDir;
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = myvars.user;
        };
      };
    };

    ## Windows network discovery (WSD) so the host shows up in Explorer
    ## without typing the address manually.
    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
  };
}
