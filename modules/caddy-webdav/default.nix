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
            "basicauth {\n          ${cfg.user} ${cfg.hashedPassword}\n        }"
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
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.storagePath != null;
            message = "services.caddy-webdav.storagePath must be set";
          }
        ];
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
        launchd.user.agents.caddy-webdav = {
          script = "exec ${lib.getExe cfg.package} run --adapter caddyfile --config ${caddyfile}";
          serviceConfig = {
            Label = "nixdwn.${username}.caddy-webdav";
            UserName = username;
            WorkingDirectory = cfg.storagePath;
            KeepAlive = true;
            RunAtLoad = true;
            StandardOutPath = "/tmp/caddy-webdav.log";
            StandardErrorPath = "/tmp/caddy-webdav.log";
            EnvironmentVariables = {
              XDG_DATA_HOME = "${homeDir}/.local/share";
            };
          };
        };
      })
    ]
  );
}
