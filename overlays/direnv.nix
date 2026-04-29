{
  ...
}:

{
  nixpkgs.overlays = [
    (final: prev: {
      direnv = prev.direnv.overrideAttrs (prevAttrs: {
        ## Workaround: direnv checkPhase hangs on aarch64-darwin due to zsh
        ## sigsuspend probe issue (nixpkgs#513019). Fixed in nixpkgs PR #513971
        ## (zsh fix), remove this override after updating nixpkgs past that commit.
        doCheck = !prev.stdenv.isDarwin;
      });
    })
  ];
}
