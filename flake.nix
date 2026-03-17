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

    my-dotzsh = {
      url = "github:handy-sun/dotzsh/dev-flake";
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
    my-dotzsh,
    my-dotfiles,
    ...
  }:
  let
    myvars = import ./lib/vars.nix;

    mkHome = arch: home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${arch};
      extraSpecialArgs = { inherit inputs myvars; };
      modules = [ ./home ];
    };

    ## for MacOS(darwin)
    system = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
    hostname = "handyMini";
    specialArgs = { inherit myvars hostname; };

    mkSystem = import ./lib/mksystem.nix {
      inherit nixpkgs inputs myvars;
    };
  in
  {
    nixosConfigurations = {
      "expnix" = mkSystem "expnix" {
        system = "aarch64-linux";
      };
    };

    ## nix-darwin
    darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
      inherit system specialArgs;
      modules = [
        ./machines/nix-core.nix
        ./machines/darwin-base.nix

        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${myvars.user} = import ./home;
          home-manager.extraSpecialArgs = { inherit inputs; } // specialArgs;
        }
      ];
    };
    # nix code formatter
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    homeConfigurations = {
      "${myvars.user}"           = mkHome "x86_64-linux";
    };
  };
}
