# Reference: caddy-webdav implementation

```
Service:       Caddy WebDAV on port 8080
Module:        modules/caddy-webdav/default.nix
Affected host: handyMini (aarch64-darwin)
Options:       enable, package, storagePath, port, user, hashedPassword
Plugin:        github.com/mholt/caddy-webdav@v0.0.0-20260127042217-fa2f366b0d75
```

## Caddy-specific config pitfalls

- **Caddyfile needs `--adapter caddyfile`**: Caddy expects JSON config by default. If you use `pkgs.writeText` to produce a Caddyfile, the `ProgramArguments` MUST include `"--adapter" "caddyfile"` before `"--config"`.

- **WebDAV is a non-ordered handler**: The `webdav` directive must be placed inside a `route { }` block. Putting it at the top level of the site block produces: `directive 'webdav' is not an ordered HTTP handler`. Same applies to `basicauth` when used alongside webdav.

- **XDG_DATA_HOME**: Caddy needs this environment variable set in the launchd agent so it can locate its certificate store. Set in `EnvironmentVariables`.

## Reference: direnv on aarch64-darwin

Root cause: zsh's `sigsuspend` probe in autoconf 2.73 / C23 hangs on aarch64-darwin.
direnv's `checkPhase` runs zsh tests, triggering the hang. Fixed in nixpkgs#513971
(zsh patch). Local overlay: skip `checkPhase` on Darwin.

```
nixpkgs issue: #513019
nixpkgs PR:    #513971
Local file:    overlays/direnv.nix
Affected host: handyMini (aarch64-darwin)
```
