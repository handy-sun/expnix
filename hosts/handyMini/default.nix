{
  pkgs,
  lib,
  username,
  myutils,
  homeDir,
  ...
}:
let
  singboxWorkDir = homeDir + "/.cache/sing-box"; # WARN: NOT reproducible
  beszelAgentEnv = homeDir + "/.config/beszel/beszel-agent.env";
in
{
  imports = (
    lib.map myutils.relativeToRoot [
      "machines/darwin-base.nix"
      "overlays/beszel.nix"
      "overlays/direnv.nix"
    ]
  );

  users.users."${username}" = {
    shell = pkgs.fish; # # Not worked, must use `chsh -s ...`
  };

  system.activationScripts.users.text = lib.mkBefore ''
    mkdir -p ${singboxWorkDir} && chown ${username}:staff ${singboxWorkDir}
  '';

  #############################################################
  ##
  ## $HOME/Library/LaunchAgents/$Label.plist
  ##
  #############################################################
  launchd.user.agents.singb.serviceConfig = {
    Label = "nixdwn.${username}.singb";
    UserName = username;
    ProgramArguments = [
      "${lib.getExe pkgs.sing-box}"
      "run"
      "-c"
      "${homeDir}/.config/sing-box/config.json"
      "-D"
      singboxWorkDir
    ];
    ThrottleInterval = 5;
    WorkingDirectory = singboxWorkDir;
    KeepAlive = true;
    RunAtLoad = true;
  };

  launchd.user.agents.frpc.serviceConfig = {
    Label = "nixdwn.${username}.frpc";
    UserName = username;
    ProgramArguments = [
      "${lib.getBin pkgs.frp}/bin/frpc"
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
      exec ${pkgs.beszel}/bin/beszel-agent "$@"
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
      "${lib.getExe pkgs.nginx}"
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

  launchd.user.agents.php-fpm.serviceConfig = {
    Label = "nixdwn.${username}.php-fpm";
    UserName = username;
    ProgramArguments = [
      "${pkgs.php}/bin/php-fpm"
      "-F"
      "-y"
      "${homeDir}/.config/php/php-fpm.conf"
    ];
    KeepAlive = true;
    RunAtLoad = true;
    StandardOutPath = "/tmp/php-fpm.out.log";
    # StandardErrorPath = "/tmp/php-fpm.err.log";
  };
}
