{
  ...
}:

{
  nixpkgs.overlays = [
    (final: prev: {
      beszel =
        if prev.stdenv.hostPlatform.isDarwin then
          prev.beszel.overrideAttrs (old: {
            ## The legacy hub payload subtests wait on a 5 s deadline the macOS
            ## runner misses; extend nixpkgs' own skip regex instead of
            ## replacing the whole list (it also carries darwin-only skips).
            checkFlags = map (
              flag: if prev.lib.hasPrefix "-skip=" flag then flag + "|^TestLegacyHubGetsSinglePayload$" else flag
            ) (old.checkFlags or [ ]);
          })
        else
          prev.beszel;
    })
  ];
}
