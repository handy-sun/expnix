{
  description = "handy-sun NixOS flake configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
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
    my-dotfiles,
    my-dotzsh,
    ...
  }:
  let
    myvars = import ./lib/vars.nix;
    mkHome = arch: home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${arch};
      extraSpecialArgs = { inherit inputs myvars; };
      modules = [ ./home ];
    };
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
      ];
    };

    homeConfigurations = {
      "${myvars.user}"           = mkHome "x86_64-linux";
      "${myvars.user}@handyMini" = mkHome "aarch64-darwin";
    };
    ## home-manager singlealone for
    # homeConfigurations."${myvars.user}" = home-manager.lib.homeManagerConfiguration {
    #   pkgs = import nixpkgs {
    #     system = "aarch64-darwin";
    #   };
    #   extraSpecialArgs = { inherit inputs myvars; };
    #   modules = [
    #     ./home
    #   ];
    # };
  };
}
