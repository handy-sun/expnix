{ lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      mtg = prev.buildGoModule rec {
        pname = "mtg";
        version = "2.2.8";

        src = prev.fetchFromGitHub {
          owner = "9seconds";
          repo = "mtg";
          rev = "v${version}";
          hash = "sha256-qRqyA40+w2dWZ+rfieniaRoKqQ9ZdTRD/sq6otDSL9g=";
        };

        vendorHash = "sha256-SHD9Hm3FUGG4YihWb0ZS1sUaAz76Ub8LR6llvnz4gEc=";

        env.CGO_ENABLED = 0;
        ldflags = [
          "-s"
          "-w"
          "-X main.version=${version}"
        ];

        subPackages = [ "." ];

        meta = {
          description = "MTProto proxy for Telegram";
          homepage = "https://github.com/9seconds/mtg";
          license = lib.licenses.mit;
          mainProgram = "mtg";
        };
      };
    })
  ];
}
