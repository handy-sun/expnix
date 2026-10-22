{ lib, ... }:

{
  nixpkgs.overlays = [
    (
      final: prev:
      let
        ## October 2026 security releases: nixpkgs#576775, #576777, #576776.
        ## Remove once nixpkgs includes both the releases and shared-library fixes.
        releases = {
          nodejs-slim_22 = {
            version = "22.23.4";
            sha256 = "7b9adc82d612d0a2a863d96c46de2292552e250cee51956ebbe0146c42aacae9";
          };
          nodejs-slim_24 = {
            version = "24.22.1";
            sha256 = "4f5379796280cdaeb0c2f358fd04b6a16cc4fb7dfa83b5a8c91a9d963b435231";
          };
          nodejs-slim_26 = {
            version = "26.12.1";
            sha256 = "053e3b296859b6d8d93f99ef97fa9cec1c4ee171c72968100c649978c1dbd38c";
          };
        };

        brotliFix = "0ed4268a4401abcb4472096340477cf4af7d1a2b";
        hasBrotliFix =
          brotli:
          lib.any (
            patch:
            lib.hasInfix brotliFix (toString patch) || lib.any (lib.hasInfix brotliFix) (patch.urls or [ ])
          ) (brotli.patches or [ ]);

        ## Inspect the libraries actually used by Node: upstream may already apply
        ## the Brotli patch locally even while the global package is still unfixed.
        dependency =
          node: name: lib.findFirst (package: (package.pname or "") == name) null node.buildInputs;
        fixedDependencies =
          node:
          let
            brotli = dependency node "brotli";
            cares = dependency node "c-ares";
            sqlite = dependency node "sqlite";
          in
          lib.optionalAttrs
            (brotli != null && lib.versionOlder brotli.version "1.2.1" && !(hasBrotliFix brotli))
            {
              ## nixpkgs#576792: CVE-2026-111497 (decoder out-of-bounds write).
              brotli = brotli.overrideAttrs (old: {
                patches = (old.patches or [ ]) ++ [
                  (final.fetchurl {
                    url = "https://github.com/google/brotli/commit/${brotliFix}.patch?full_index=1";
                    hash = "sha256-1vliUJAAIj3vcGKVgim9CEV+XgMuftDR2U+3kLBUsfw=";
                  })
                ];
              });
            }
          // lib.optionalAttrs (cares != null && lib.versionOlder cares.version "1.34.9") {
            ## nixpkgs#576217: use the c-ares release shipped by the security update.
            c-ares = cares.overrideAttrs {
              version = "1.34.9";
              src = final.fetchurl {
                url = "https://github.com/c-ares/c-ares/releases/download/v1.34.9/c-ares-1.34.9.tar.gz";
                hash = "sha256-k2S3ChLrWaBoMPtIjZNX+QEA3/DZiyPqNZOhg9Q+by8=";
              };
            };
          }
          // lib.optionalAttrs (sqlite != null && lib.versionOlder sqlite.version "3.53.4") {
            ## Sources from nixpkgs#547246; matches the Node 22/24 security baseline.
            ## Keep this local to Node; SQLite's other tools remain on nixpkgs' version.
            sqlite = sqlite.overrideAttrs {
              version = "3.53.4";
              src = final.fetchurl {
                url = "https://sqlite.org/2026/sqlite-src-3530400.zip";
                hash = "sha256-0Y+hWux02MF+FGP4YQla3AG1rRkCVqy0+R0i8DaNIys=";
              };
              docsrc = final.fetchurl {
                url = "https://sqlite.org/2026/sqlite-doc-3530400.zip";
                hash = "sha256-odD13ldIXQYnlu1+Z9r/B1i1DQAAGg8jOiwVqvQLvcg=";
              };
            };
          };
      in
      lib.mapAttrs (
        name: release:
        let
          node = prev.${name};
          needsRelease = lib.versionOlder node.version release.version;
          dependencies = fixedDependencies node;
        in
        if needsRelease || dependencies != { } then
          node.override (original: {
            ## Pass the release through the builder so npm, corepack, tests and
            ## version-dependent build logic all use the new version together.
            ## Preserve existing callPackage wrappers and branch-specific arguments.
            callPackage =
              path: args:
              let
                builder = if builtins.isFunction path then path else import path;
                securedBuilder = lib.setFunctionArgs (
                  builderArgs: nodeArgs:
                  builder (builderArgs // dependencies) (
                    nodeArgs // lib.optionalAttrs (lib.versionOlder nodeArgs.version release.version) release
                  )
                ) (lib.functionArgs builder);
              in
              original.callPackage securedBuilder args;
          })
        else
          node
      ) (lib.filterAttrs (name: _: builtins.hasAttr name prev) releases)
    )
  ];
}
