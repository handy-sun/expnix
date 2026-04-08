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
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      nixos-wsl,
      home-manager,
      my-nvimdots,
      my-dotzsh,
      my-dotvim,
      my-dotfiles,
      ...
    }:
    let
      appleSiliconSystem = "aarch64-darwin";

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
    in
    {
      nixosConfigurations = {
        "expnix" = mkSystem "expnix" {
          system = "aarch64-linux";
        };

        "nixwsl" = mkSystem "nixwsl" {
          system = "x86_64-linux";
          isWSL = true;
        };
      };

      darwinConfigurations = {
        "handyMini" = mkSystem "handyMini" {
          system = appleSiliconSystem;
          isDarwin = true;
        };
      };

      homeConfigurations = {
        "${myvars.user}" = mkHome "x86_64-linux" { };
      };

      # nix code formatter
      formatter.${appleSiliconSystem} = nixpkgs.legacyPackages.${appleSiliconSystem}.nixfmt;
    };
}
