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
        ./machines/orb-base.nix
        ./nixos/pkgenv.nix 
        ./nixos/services.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${myvars.user} = import ./home;
          home-manager.extraSpecialArgs = { inherit inputs myvars; };
        }
        # ({ pkgs, ... }: {
        #   nixpkgs.overlays = [ rust-overlay.overlays.default ];
        #   environment.systemPackages = [ pkgs.rust-bin.stable.latest.default ];
        # })
      ];
    };

    ## home-manager singlealone for x86_64-linux"
    homeConfigurations."${myvars.user}" = home-manager.lib.homeManagerConfiguration {
      # inherit pkgs;
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        # overlays = [ rust-overlay.overlays.default ];
      };
      extraSpecialArgs = { inherit inputs myvars; };
      modules = [
        ./home
      ];
    };
  };
}
