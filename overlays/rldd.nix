{ lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      rldd = prev.rustPlatform.buildRustPackage rec {
        pname = "rldd";
        version = "0.3.0";

        src = prev.fetchCrate {
          inherit pname version;
          hash = "sha256-DhMEckfubYtVrvA/H/p1J9KjAI5rWsZSt9SL5CnyCzQ=";
        };

        cargoHash = "sha256-Re5+3hhl80X8sPlZWNT2ZwKkVU8ICMcv2cle26UJurI=";

        meta = {
          description = "A program to print shared object dependencies";
          homepage = "https://github.com/zatrazz/rldd";
          license = lib.licenses.mit;
          mainProgram = "rldd";
        };
      };
    })
  ];
}
