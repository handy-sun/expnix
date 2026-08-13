{ inputs, lib, ... }:

{
  relativeToRoot = lib.path.append ../.;

  mkNixPakPackage =
    pkgs: path:
    pkgs.callPackage path {
      mkNixPak = inputs.nixpak.lib.nixpak {
        inherit pkgs;
        inherit (pkgs) lib;
      };
      mkNixPakAppWrapper =
        package:
        {
          binPath ? "bin/${builtins.baseNameOf (lib.getExe package)}",
          prefixPaths ? [ pkgs.flatpak-xdg-utils ],
          prefixLibraries ? [ pkgs.libx11 ],
          extraWrapperArgs ? [ ],
        }:
        let
          mainProgram = builtins.baseNameOf binPath;
          wrapperArgs =
            lib.optionals (prefixPaths != [ ]) [
              "--prefix"
              "PATH"
              ":"
              (lib.makeBinPath prefixPaths)
            ]
            ++ lib.optionals (prefixLibraries != [ ]) [
              "--prefix"
              "LD_LIBRARY_PATH"
              ":"
              (lib.makeLibraryPath prefixLibraries)
            ]
            ++ extraWrapperArgs;
        in
        pkgs.runCommandLocal "nixpak-app-wrapper-${mainProgram}"
          {
            inherit (package) passthru;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            meta.mainProgram = mainProgram;
          }
          ''
            makeWrapper ${lib.escapeShellArg "${package}/${binPath}"} \
              "$out/bin/${mainProgram}" ${lib.escapeShellArgs wrapperArgs}
          '';
    };

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
