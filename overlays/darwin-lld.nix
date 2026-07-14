{ lib, ... }:

{
  nixpkgs.overlays = [
    (
      final: prev:
      let
        useLld =
          package:
          package.overrideAttrs (old: {
            ## ld64 built with libcxxhardeningfast traps while linking these packages.
            ## Remove after nixpkgs#536365 reaches nixpkgs-unstable.
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages.lld ];
            env = (old.env or { }) // {
              NIX_CFLAGS_LINK = "-fuse-ld=lld";
            };
          });
      in
      lib.optionalAttrs prev.stdenv.isDarwin {
        moonlight-qt = useLld prev.moonlight-qt;
        mpv-unwrapped = useLld prev.mpv-unwrapped;
      }
    )
  ];
}
