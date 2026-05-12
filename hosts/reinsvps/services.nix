_: {
  services = {
    rustdesk-server = {
      enable = true;
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
