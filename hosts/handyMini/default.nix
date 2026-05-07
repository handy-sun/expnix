{
  pkgs,
  lib,
  username,
  myutils,
  homeDir,
  inputs,
  ...
}:
let
  beszelAgentEnv = homeDir + "/.config/beszel/beszel-agent.env";
  webdavConf = inputs.my-dotfiles + "/.config/webdav/config.yml";
in
{
  imports = (
    lib.map myutils.relativeToRoot [
      "machines/darwin-base.nix"
      "overlays/beszel.nix"
      "overlays/direnv.nix"
      "modules/caddy-webdav"
      "modules/sing-box/darwin.nix"
    ]
  );

  users.users."${username}" = {
    shell = pkgs.fish; # # Not worked, must use `chsh -s ...`
  };

  services.sing-box = {
    enable = true;
    configGeneration = {
      enable = true;
      sourceUrl = "http://handy:3001/c53248f264d9997/download/collection/main?target=V2Ray";
      policyFilter = "@🌐Proxy@⚡UrlTest-~^(?!.*(aote|流量|到期|过滤|官网)).*$@💬AI-~^(?!.*(流量|到期|过滤|官网)).*$@🚀LowLatency-~^(?!.*(流量|到期|过滤|官网)).*$";
      extraArgs = [
        "--log-file"
        ""
        "--icmp"
      ];
    };
  };

  launchd.user.agents.frpc.serviceConfig = {
    Label = "nixdwn.${username}.frpc";
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

  launchd.user.agents.webdav.serviceConfig = {
    Label = "nixdwn.${username}.webdav";
    ProgramArguments = [
      "${lib.getExe pkgs.webdav}"
      "-c"
      "${webdavConf}"
    ];
    KeepAlive = true;
    RunAtLoad = true;
  };
}
