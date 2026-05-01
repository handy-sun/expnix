{
  description = "handy-sun NixOS flake configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    my-nvimdots.url = "github:handy-sun/nvimdots";

    my-dotzsh.url = "github:handy-sun/dotzsh";

    my-dotvim = {
      url = "github:handy-sun/dotvim";
      flake = false;
    };

    my-dotfiles = {
      url = "github:handy-sun/dotfiles";
      flake = false;
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sbtpl = {
      url = "git+https://codeberg.org/handy/sbtpl.git";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      nixos-wsl,
      home-manager,
      rust-overlay,
      my-nvimdots,
      my-dotzsh,
      my-dotvim,
      my-dotfiles,
      ...
    }:
    let
      allSystemNames = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      myvars = import ./lib/vars.nix;
      myutils = import ./lib/utils.nix { inherit (nixpkgs) lib; };

      mkHome = import ./lib/mkhome.nix {
        inherit
          nixpkgs
          inputs
          myvars
          myutils
          ;
      };

      mkSystem = import ./lib/mksystem.nix {
        inherit
          nixpkgs
          inputs
          myvars
          myutils
          ;
      };

      forAllSystems = func: (nixpkgs.lib.genAttrs allSystemNames func);
    in
    {
      nixosConfigurations = {
        "expnix" = mkSystem "expnix" {
          system = "aarch64-linux";
          profileLevel = {
            tuiAdvanced = true;
            tuiOptional = true;
            guiBase = false;
            guiHeavy = false;
          };
        };

        "nixwsl" = mkSystem "nixwsl" {
          system = "x86_64-linux";
          isWSL = true;
          profileLevel = {
            tuiAdvanced = true;
            tuiOptional = false;
            guiBase = false;
            guiHeavy = false;
          };
        };
      };

      darwinConfigurations = {
        "handyMini" = mkSystem "handyMini" {
          system = "aarch64-darwin";
          isDarwin = true;
          profileLevel = {
            tuiAdvanced = true;
            tuiOptional = true;
            guiBase = true;
            guiHeavy = false;
          };
        };
      };

      homeConfigurations = {
        "${myvars.user}" = mkHome "x86_64-linux" { };
      };

      ##  Development Shells
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              statix
              typos
            ];
            name = "devsh";
            shellHook = ''
              echo "Welcome to expnix devshell"
              exec fish -il
            '';
          };
        }
      );

      ## nix code formatter
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
