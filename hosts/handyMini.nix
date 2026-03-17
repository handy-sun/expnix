{ lib, hostName, ... }:

{
  imports = [
    ../machines/darwin-base.nix
  ];

  ## COMMAND: scutil --get HostName (HostName: not set)
  networking.hostName = hostName;
  ## COMMAND: scutil --get ComputerName
  networking.computerName = hostName;

  system.defaults.smb.NetBIOSName = hostName;
}