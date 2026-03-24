{
  pkgs,
  lib,
  username,
  hostName,
  ...
}:
let
  singboxDir = "/opt/sing-box";
  singbExePath = lib.getExe pkgs.sing-box;
  frpcExePath = "${lib.getBin pkgs.frp}/bin/frpc";
  nginxExePath = lib.getExe pkgs.nginx;
in
{
  imports = [
    ../machines/darwin-base.nix
  ];

  ## COMMAND: scutil --get ComputerName
  networking.computerName = hostName;

  system.defaults.smb.NetBIOSName = hostName;
  users.users."${username}" = {
    ## Not worked, must use `chsh -s ...`
    shell = pkgs.fish;
  };

  ## $HOME/Library/LaunchAgents/$Label.plist
  launchd.user.agents.singb.serviceConfig = {
    Label = "nixdwn.${username}.singb";
    UserName = username;
    ProgramArguments = [
      "${singbExePath}"
      "run"
      "-c"
      "${singboxDir}/config.json"
      "-D"
      "${singboxDir}/var"
    ];
    ThrottleInterval = 5;
    WorkingDirectory = "${singboxDir}";
    KeepAlive = true;
    RunAtLoad = true;
  };

  launchd.user.agents.frpc.serviceConfig = {
    Label = "nixdwn.${username}.frpc";
    UserName = username;
    ProgramArguments = [
      "${frpcExePath}"
      "-c"
      "/etc/frp/frpc.toml"
    ];
    KeepAlive = true;
    RunAtLoad = true;
  };

  ## /Library/LaunchDaemons/$Label.plist
  launchd.daemons.nginx.serviceConfig = {
    Label = "nixdwn.handy.nginx";
    UserName = "root";
    ProgramArguments = [
      "${nginxExePath}"
      "-c"
      "/etc/nginx/nginx.conf"
      "-g"
      "daemon off;"
    ];
    KeepAlive = true;
    RunAtLoad = true;
  };

}
