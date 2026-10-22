{ lib, ... }:

{
  nixpkgs.overlays = [
    (
      _: prev:
      let
        ## Backport nixpkgs#576853 / #576865 for CVE-2026-109618 and CVE-2026-109619.
        ## Stop overriding each branch once the pinned nixpkgs has its fixed release.
        releases = {
          php82 = {
            version = "8.2.35";
            hash = "sha256-D0Pv0awk1PkAAsjU1XC/TE1Z+hQxO/JwqujPBNnf3vM=";
          };
          php83 = {
            version = "8.3.36";
            hash = "sha256-RvS0XjaI7SsYGQFae1MsFbUcwFW907E/0A3f7r7tzV8=";
          };
          php84 = {
            version = "8.4.27";
            hash = "sha256-slMKh3xyL0sIyeF0owywi6wrfhkD7m6eMV8KqfX4LCQ=";
          };
          php85 = {
            version = "8.5.12";
            hash = "sha256-/7YO3EN87WO1E35JhNs3moERxQBJxxFRDYuVgnfvwag=";
          };
        };
      in
      lib.mapAttrs (
        name: release:
        let
          php = prev.${name};
        in
        if lib.versionOlder php.version release.version then
          (php.override (
            release
            // {
              ## Update the interpreter and every bundled extension together.
              packageOverrides = _: packages: {
                extensions = packages.extensions // {
                  filter = packages.extensions.filter.overrideAttrs (old: {
                    ## Upstream's new regression tests spawn PHP without loading extensions.
                    postConfigure = (old.postConfigure or "") + ''
                      substituteInPlace \
                        tests/oom_filter_input.phpt \
                        tests/oom_filter_input_array.phpt \
                        tests/oom_filter_default_encoded.phpt \
                        --replace-fail "'-n'," "'-n', '-d', 'extension=$PWD/modules/filter.so',"
                    '';
                  });
                };
              };
            }
          )).overrideAttrs
            ## Refresh generic.nix's closure so packageOverrides reaches the extensions.
            (_: { })
        else
          php
      ) (lib.filterAttrs (name: _: builtins.hasAttr name prev) releases)
    )
  ];
}
