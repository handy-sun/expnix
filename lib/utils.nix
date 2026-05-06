{ lib, ... }:

{
  relativeToRoot = lib.path.append ../.;

  ## Resolve a list of dotted attribute name strings to actual packages from pkgs.
  ## e.g. resolveNames pkgs [ "nerd-fonts.symbols-only" "fira-code" ]
  resolveNames =
    pkgs: names: builtins.map (name: lib.attrByPath (lib.splitString "." name) null pkgs) names;

  scanPaths =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
          (_type == "directory") # include directories
          || (
            (path != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" path) # include .nix files
          )
        ) (builtins.readDir path)
      )
    );
}
