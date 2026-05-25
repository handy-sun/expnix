{ myutils, ... }:
{
  imports = [
    (myutils.relativeToRoot "modules/mtg")
  ];

  services = {
    mtg = {
      enable = false; # set to true and fill in secret to activate
      secret = null; # e.g. "ee..." or base64 string
      bind = "0.0.0.0:443";
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
