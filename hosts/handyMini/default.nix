{
  pkgs,
  lib,
  username,
  myutils,
  homeDir,
  ...
}:
let
  singboxDir = "/opt/sing-box"; # # WARN: NOT reproducible
  singbExePath = lib.getExe pkgs.sing-box;
  frpcExePath = "${lib.getBin pkgs.frp}/bin/frpc";
  nginxExePath = lib.getExe pkgs.nginx;
  beszelAgentExePath = "${pkgs.beszel}/bin/beszel-agent";
  beszelAgentEnv = homeDir + "/.config/beszel/beszel-agent.env";
in
{
  imports = [
    (myutils.relativeToRoot "machines/darwin-base.nix")
  ];

  users.users."${username}" = {
    shell = pkgs.fish; # # Not worked, must use `chsh -s ...`
  };

  #############################################################
  ##
  ## $HOME/Library/LaunchAgents/$Label.plist
  ##
  #############################################################
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

  launchd.user.agents.beszel-agent = {
    script = ''
      #!/usr/bin/env bash
      set -a
      test -f ${beszelAgentEnv} && source ${beszelAgentEnv}
      set +a
      exec ${beszelAgentExePath} "$@"
    '';
    serviceConfig = {
      Label = "nixdwn.${username}.beszel-agent";
      UserName = username;
      LimitLoadToHosts = [
        "Aqua"
        "Background"
        "LoginWindow"
        "StandardIO"
        "System"
      ];
      ProcessType = "Background";
      KeepAlive = true;
      RunAtLoad = true;
      ThrottleInterval = 5;
      StandardErrorPath = "/tmp/beszel-agent.log";
      StandardOutPath = "/tmp/beszel-agent.log";
    };
  };

  launchd.user.agents.nginx.serviceConfig = {
    Label = "nixdwn.${username}.nginx";
    UserName = username;
    ProgramArguments = [
      "${nginxExePath}"
      "-e"
      "stderr"
      "-c"
      "/etc/nginx/nginx.conf"
      "-g"
      "daemon off;"
    ];
    KeepAlive = true;
    RunAtLoad = true;
  };
  #############################################################
  ##
  ## /Library/LaunchDaemons/$Label.plist
  ##
  #############################################################
  # launchd.daemons.nginx.serviceConfig = {
  #   Label = "nixdwn.handy.nginx";
  #   UserName = "root";
  #   ProgramArguments = [
  #     "${nginxExePath}"
  #     "-c"
  #     "/etc/nginx/nginx.conf"
  #     "-g"
  #     "daemon off;"
  #   ];
  #   KeepAlive = true;
  #   RunAtLoad = true;
  # };
}
