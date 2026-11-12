{
  ...
}:

{
  nixpkgs.overlays = [
    (
      final: prev:
      prev.lib.optionalAttrs (prev.stdenv.hostPlatform.isLinux && prev ? rustdesk-flutter) {
        ## rustdesk 1.5.0 links libsodium-sys, but the nixpkgs recipe does not list
        ## libsodium, so the crate's build script aborts looking for libsodium.pc.
        rustdesk-flutter = prev.rustdesk-flutter.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ [ prev.libsodium ];
        });
      }
    )
  ];
}
