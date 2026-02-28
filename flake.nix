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
  };

  outputs = inputs @ { nixpkgs, home-manager, rust-overlay, ... }: {
    # expnix: your hostname
    nixosConfigurations.expnix = nixpkgs.lib.nixosSystem {
      # system = "aarch64-linux";  # 指定 ARM64 架构（legacy，但兼容）
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.qi = import ./home/qi.nix;
          home-manager.extraSpecialArgs = inputs;
        }
        ({ pkgs, ... }: { ## Can use 'cargo -V' directly
          nixpkgs.overlays = [ rust-overlay.overlays.default ];
          environment.systemPackages = with pkgs; [
            rust-bin.stable.latest.default
          ];
        })
      ];
    };
  };
}
