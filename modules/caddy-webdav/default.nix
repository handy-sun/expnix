{
  config,
  lib,
  pkgs,
  username,
  homeDir,
  isDarwin,
  ...
}:
let
  cfg = config.services.caddy-webdav;
  caddyfile = pkgs.writeText "Caddyfile-webdav" ''
    :${builtins.toString cfg.port} {
      root * ${cfg.storagePath}
      ${if cfg.user != null && cfg.hashedPassword != null then
        "basicauth {\n        ${cfg.user} ${cfg.hashedPassword}\n      }"
      else ""}
      webdav
    }
  '';
in
{
  options.services.caddy-webdav = {
    enable = lib.mkEnableOption "Caddy WebDAV server";

    package = lib.mkPackageOption pkgs "caddy-webdav" { };

    storagePath = lib.mkOption {
      type = lib.types.str;
      default = "/var/www/webdav";
      description = "Directory to serve via WebDAV";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Username for basic auth (null = no auth)";
    };

    hashedPassword = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Hashed password for basic auth (run: caddy hash-password)";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ cfg.package ];
      }
      # Ensure storage directory exists with correct ownership
      {
        system.activationScripts.caddy-webdav.text = ''
          mkdir -p ${cfg.storagePath}
          chown ${username}:staff ${cfg.storagePath}
        '';
      }
      # Darwin launchd agent
      (lib.mkIf isDarwin {
        launchd.user.agents.caddy-webdav.serviceConfig = {
          Label = "nixdwn.${username}.caddy-webdav";
          UserName = username;
          ProgramArguments = [
            "${lib.getExe cfg.package}"
            "run"
            "--config"
            "${caddyfile}"
          ];
          WorkingDirectory = cfg.storagePath;
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "/tmp/caddy-webdav.log";
          StandardErrorPath = "/tmp/caddy-webdav.log";
          EnvironmentVariables = {
            XDG_DATA_HOME = "${homeDir}/.local/share";
          };
        };
      })
    ]
  );
}
