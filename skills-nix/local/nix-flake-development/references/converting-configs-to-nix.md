# Converting Traditional Config Files to Nix Modules

When migrating from hand-managed config files (nginx.conf, docker-compose.yml, etc.) to declarative Nix modules.

## Workflow

1. **Read the original config** — understand structure, identify reusable parts vs host-specific values
2. **Extract variables** — domain names, ports, paths should become options, not hardcoded
3. **Design options** — use `lib.mkOption` for each configurable aspect
4. **Use attrsOf submodule** for collections (multiple proxy sites, multiple users, etc.)
5. **Generate config** — use `environment.etc` or writeText to produce the actual config file
6. **Add launchd/systemd** — wrap in service definition using `lib.mkIf isDarwin`

## Example: nginx.conf → Nix Module

### Original config patterns to extract:

```nginx
server {
  listen 1080;
  server_name hals.647792.xyz;
  location / {
    proxy_pass http://localhost:5244;
  }
}
```

### Nix module with generic options:

```nix
options.services.nginx-custom = {
  # Simple options
  enable = lib.mkEnableOption "Custom nginx server";
  workerProcesses = lib.mkOption { type = lib.types.int; default = 4; };
  
  # Boolean toggles for features
  enablePhpFpm = lib.mkOption { type = lib.types.bool; default = false; };
  
  # attrsOf submodule for collections (key pattern!)
  proxyConfigs = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        serverName = lib.mkOption { type = lib.types.str; };
        port = lib.mkOption { type = lib.types.port; };
        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Extra location config";
        };
      };
    });
    default = {};
  };
};
```

### Using attrsOf submodule in config generation:

```nix
config = lib.mkIf cfg.enable {
  environment.etc."nginx/nginx.conf".text = ''
    http {
      # Static sections...
      
      # Dynamic generation from proxyConfigs
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: proxyCfg: ''
        server {
          listen 1080;
          server_name ${proxyCfg.serverName};
          location / {
            proxy_pass http://localhost:${toString proxyCfg.port};
            ${proxyCfg.extraConfig}
          }
        }
      '') cfg.proxyConfigs)}
    }
  '';
};
```

### Host usage:

```nix
# hosts/handyMini/default.nix
services.nginx-custom = {
  enable = true;
  proxyConfigs = {
    hals = { serverName = "hals.647792.xyz"; port = 5244; };
    tea = {
      serverName = "tea.647792.xyz";
      port = 3200;
      extraConfig = ''
        client_max_body_size 1024M;
        proxy_set_header Upgrade $http_upgrade;
      '';
    };
  };
};
```

## Key Design Principles

1. **Generic module, specific host config** — module defines structure, host provides values
2. **Use `lib.concatStringsSep` + `lib.mapAttrsToList`** for generating repeated blocks
3. **`extraConfig` escape hatch** — always include an `extraConfig` option for edge cases
4. **Domain as variable** — define domain in `let` block, use `${domain}` interpolation
5. **User-level services** — use `launchd.user.agents` (not system-level) to avoid root
6. **Activation scripts** — use `system.activationScripts` to create directories with correct ownership

## Pitfalls

- **Don't hardcode paths** — use options for storage paths, config paths
- **Don't hardcode users** — accept `username` from specialArgs, use it in launchd Label
- **Remember `lib.mkIf`** — wrap config in `lib.mkIf cfg.enable` so options are evaluated even when disabled
- **attrsOf keys are arbitrary** — the key (e.g., "hals") is just a Nix identifier, not used in config unless you reference `name`
