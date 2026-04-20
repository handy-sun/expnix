{
  ...
}:

{
  nixpkgs.overlays = [
    (final: prev: {
      deno = prev.deno.overrideAttrs (prevAttrs: {
        patches = builtins.filter (
          p: !(prev.lib.hasInfix "fd331552" (baseNameOf (toString p)))
        ) prevAttrs.patches;
      });
    })
  ];
}
