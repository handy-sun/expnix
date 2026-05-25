{ pkgs, myutils, ... }:
{
  imports = [
    (myutils.relativeToRoot "modules/mtg")
  ];

  environment.systemPackages = [ pkgs.mtg ];

  services = {
    mtg = {
      enable = false; # set to true to activate
      settings = {
        bind-to = "0.0.0.0:11443";
        secret = "00000000000000000000aaaaaaaaaaaaaaaa";
        defense.doppelganger.urls = [
          "https://lalala.com/index.html"
          "https://lalala.com/contacts.html"
        ];
      };
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
