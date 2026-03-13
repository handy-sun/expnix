{
  description = "handy-sun NixOS flake configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
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
    home-manager,
    nix-darwin,
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
    ## DONE: replace with your own username, system and hostname
    username = "qi";
    system = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
    hostname = "handyMini";

    specialArgs =
      inputs
      // {
        inherit username hostname;
      };
  in
  {
    nixosConfigurations.expnix = nixpkgs.lib.nixosSystem {
      modules = [
        ./machines/nix-core.nix
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

    ## nix-darwin
    darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
      inherit system specialArgs;
      modules = [
        ./machines/nix-core.nix
        ./machines/darwin-base.nix
      ];
    };
    # nix code formatter
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    homeConfigurations = {
      "${myvars.user}"           = mkHome "x86_64-linux";
      "${myvars.user}@handyMini" = mkHome "aarch64-darwin";
    };
  };
}
