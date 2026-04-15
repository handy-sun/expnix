{
  ...
}:

let
  beszelVersion = "0.18.4";
in
{
  nixpkgs.overlays = [
    (final: prev: {
      beszel = prev.beszel.overrideAttrs (
        finalAttrs: prevAttrs: {
          version = beszelVersion;
          src = prev.fetchFromGitHub {
            owner = "henrygd";
            repo = "beszel";
            tag = "v${finalAttrs.version}";
            hash = "sha256-Ugxy23bLrKIDclrYRFJc6Nq4Ak2S3OLeyMaxuRkS/tY=";
          };
          vendorHash = "sha256-V9P3VP4CsboaWPIt/MhtxYDsYH3pwKL4xK5YcLKgbI8=";

          tags = [ ];
          checkFlags = [ ];
        }
      );
    })
  ];
}
