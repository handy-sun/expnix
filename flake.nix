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
    my-dotzsh= {
      url = "github:handy-sun/dotzsh/dev-flake";
    };
    my-dotfiles = {
      url = "github:handy-sun/dotfiles/main"; # main branch don't use git submodules
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
  let
    myvars = import ./lib/vars.nix;
  in
  {
    nixosConfigurations.expnix = nixpkgs.lib.nixosSystem {
      modules = [
        # ./configuration.nix
        # Include the OrbStack-specific configuration.
        ./machines/orb-base.nix
        # system packages, enviroment, other settings
        ./nixos/pkgenv.nix 
        # system services, virtualisation
        ./nixos/services.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${myvars.user} = import ./home;
          home-manager.extraSpecialArgs = { inherit inputs myvars; };
        }
        ({ pkgs, ... }: { ## Can use 'cargo -V' directly
          nixpkgs.overlays = [ rust-overlay.overlays.default ];
          environment.systemPackages = [ pkgs.rust-bin.stable.latest.default ];
        })
      ];
    };
  };
}
