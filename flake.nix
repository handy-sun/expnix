{
  description = "handy-sun NixOS flake configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    my-dotfiles = {
      url = "github:handy-sun/dotfiles/main"; # main branch don't use git submodules
      flake = false;
    };
    my-dotzsh= {
      url = "github:handy-sun/dotzsh";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    rust-overlay,
    my-dotfiles,
    my-dotzsh,
    ...
  }:
  {
    ## expnix: your hostname
    nixosConfigurations.expnix = nixpkgs.lib.nixosSystem {
      # system = "aarch64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.qi = import ./home;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
        ({ pkgs, ... }: { ## Can use 'cargo -V' directly
          nixpkgs.overlays = [ rust-overlay.overlays.default ];
          environment.systemPackages = [ pkgs.rust-bin.stable.latest.default ];
        })
      ];
    };
  };
}
