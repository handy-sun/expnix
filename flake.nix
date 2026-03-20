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

    nvimdots = {
      url = "github:handy-sun/nvimdots";
   };

    my-dotzsh = {
      url = "github:handy-sun/dotzsh";
    };
    my-dotfiles = {
      url = "github:handy-sun/dotfiles/main"; # main branch don't use git submodules
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs,
    nix-darwin,
    nixos-wsl,
    home-manager,
    nvimdots,
    my-dotzsh,
    my-dotfiles,
    ...
  }:
  let
    myvars = import ./lib/vars.nix;

    appleSiliconSystem = "aarch64-darwin";

    mkHome = import ./lib/mkhome.nix {
      inherit nixpkgs inputs myvars;
    };

    mkSystem = import ./lib/mksystem.nix {
      inherit nixpkgs inputs myvars;
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
      "${myvars.user}" = mkHome "x86_64-linux" {};
    };

    # nix code formatter
    formatter.${appleSiliconSystem} = nixpkgs.legacyPackages.${appleSiliconSystem}.alejandra;
  };
}
