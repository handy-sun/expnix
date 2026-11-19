{
  ...
}:

{
  nixpkgs.overlays = [
    (
      final: prev:
      prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
        ## nginx 1.30.7 / 1.31.9 are the security releases for the nginx2root
        ## set (CVE-2026-123007, -123633, -123634, -121810, -113425 plus
        ## CVE-2026-125283); the pinned nixpkgs still ships 1.30.6 / 1.31.8.
        ## Bump only the tarball and keep the rest of the recipe intact.
        nginxStable = prev.nginxStable.overrideAttrs (old: {
          version = "1.30.7";
          nginxVersion = "1.30.7";
          src = prev.fetchurl {
            url = "https://nginx.org/download/nginx-1.30.7.tar.gz";
            hash = "sha256-JWW1yDcFDpWPcPsPc8SOK8pFQq00n9NW9G+wxyYQvG4=";
          };
        });

        nginxMainline = prev.nginxMainline.overrideAttrs (old: {
          version = "1.31.9";
          nginxVersion = "1.31.9";
          src = prev.fetchurl {
            url = "https://nginx.org/download/nginx-1.31.9.tar.gz";
            hash = "sha256-oRxe7uLiV/RHjw5kn4SwBAeH0nfS0+UjOVKqa23LgK0=";
          };
        });

        ## nginx is only an alias for nginxStable; point it at the patched one.
        nginx = final.nginxStable;
      }
    )
  ];
}
