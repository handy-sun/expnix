{
  config,
  lib,
  options,
  pkgs,
  username,
  homeDir,
  ...
}:
let
  cfg = config.services.caddy-webdav;
  hasLaunchd = builtins.hasAttr "launchd" options;
  hasSystemd = builtins.hasAttr "systemd" options;

  # Build caddy with webdav plugin directly (no overlay)
  caddy-webdav-pkg = pkgs.caddy.withPlugins {
    plugins = [
      "github.com/mholt/caddy-webdav@v0.0.0-20260127042217-fa2f366b0d75"
    ];
    hash = "sha256-itDJ76e3pNZmG4cAX07cuu+Vx2qLfvp9ljfu5ln4WDc=";
  };

  caddyfile = pkgs.writeText "Caddyfile-webdav" ''
    :${builtins.toString cfg.port} {
      root * ${cfg.storagePath}
      route {
        ${
          if cfg.user != null && cfg.hashedPassword != null then
            ''
              basicauth {
                ${cfg.user} ${cfg.hashedPassword}
              }
            ''
          else
            ""
        }
        webdav
      }
    }
  '';
in
{
  options.services.caddy-webdav = {
    enable = lib.mkEnableOption "Caddy WebDAV server";

    package = lib.mkOption {
      type = lib.types.package;
      default = caddy-webdav-pkg;
      description = "Caddy package with webdav plugin";
    };

    storagePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Directory to serve via WebDAV (required)";
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
    lib.mkMerge ([
      {
        assertions = [
          {
            assertion = cfg.storagePath != null;
            message = "services.caddy-webdav.storagePath must be set";
          }
          {
            assertion = hasLaunchd || hasSystemd;
            message = "services.caddy-webdav requires either launchd or systemd support";
          }
        ];
        environment.systemPackages = [ cfg.package ];
      }
      (
        if hasLaunchd then
          {
            # Darwin uses 'staff' group.
            system.activationScripts.caddy-webdav.text = ''
              mkdir -p ${cfg.storagePath}
              chown ${username}:staff ${cfg.storagePath}
            '';
            launchd.user.agents.caddy-webdav.serviceConfig = {
              Label = "nixdwn.${username}.caddy-webdav";
              UserName = username;
              ProgramArguments = [
                "${lib.getExe cfg.package}"
                "run"
                "--adapter"
                "caddyfile"
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
          }
        else if hasSystemd then
          {
            # NixOS mirrors the configured user's home ownership.
            system.activationScripts.caddy-webdav = {
              deps = [ "users" ];
              text = ''
                mkdir -p "${cfg.storagePath}"
                chown --reference="${homeDir}" "${cfg.storagePath}"
              '';
            };
            systemd.services.caddy-webdav = {
              description = "Caddy WebDAV server";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              environment = {
                XDG_DATA_HOME = "${homeDir}/.local/share";
              };
              serviceConfig = {
                User = username;
                WorkingDirectory = cfg.storagePath;
                ExecStart = "${lib.getExe cfg.package} run --adapter caddyfile --config ${caddyfile}";
                Restart = "on-failure";
              };
            };
          }
        else
          { }
      )
    ])
  );
}
