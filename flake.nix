{
  description = "handy-sun NixOS flake configuration";

  nixConfig = {
    bash-prompt = "\\[\\e[0m\\]\\[\\033[0;32m\\]\\A (develop) \\[\\e[0;36m\\]\\w \\[\\e[0m\\]\\\\$\\[\\e[0m\\] ";
  };

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

    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix-dev = {
      url = "github:erasin/helix/local-dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ## ------ my applications, configs and scripts ------
    cc-switch-tui = {
      url = "github:handy-sun/cc-switch-tui";
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

    my-wezterm = {
      url = "github:handy-sun/wezterm-config/nix-hm?shallow=1";
      flake = false;
    };

    my-helix-config = {
      url = "github:handy-sun/helix-config";
      flake = false;
    };

    sbtpl = {
      url = "github:handy-sun/sbtpl";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      lib = nixpkgs.lib;

      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      formatterSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forFormatterSystems = lib.genAttrs formatterSystems;

      myvars = import ./lib/vars.nix;
      myutils = import ./lib/utils.nix { inherit (nixpkgs) lib; };
      networkingVars = import ./lib/networking.nix {
        inherit lib;
        inherit myvars;
        username = myvars.user;
      };

      mkHome = import ./lib/mkhome.nix {
        inherit
          nixpkgs
          inputs
          myvars
          myutils
          networkingVars
          ;
      };

      mkSystem = import ./lib/mksystem.nix {
        inherit
          nixpkgs
          inputs
          self
          myvars
          myutils
          networkingVars
          ;
      };

      mkSysMgr = import ./lib/mksysmgr.nix {
        inherit
          nixpkgs
          inputs
          myvars
          myutils
          networkingVars
          ;
      };
    in
    {
      nixosConfigurations = {
        "orbvmnix" = mkSystem "orbvmnix" {
          system = "aarch64-linux";
          profileLevelOver = {
            tuiOptional = true;
          };
        };

        "reinsvps" = mkSystem "reinsvps" {
          system = "x86_64-linux";
        };

        "nixwsl" = mkSystem "nixwsl" {
          system = "x86_64-linux";
          isWSL = true;
          profileLevelOver = {
            tuiOptional = true;
            guiBase = true;
          };
        };

        "buking" = mkSystem "buking" {
          system = "x86_64-linux";
          profileLevelOver = {
            tuiOptional = true;
            guiBase = true;
            guiHeavy = true;
          };
        };
      };

      darwinConfigurations = {
        "handyMini" = mkSystem "handyMini" {
          system = "aarch64-darwin";
          isDarwin = true;
          profileLevelOver = {
            tuiOptional = true;
            guiBase = true;
          };
        };
      };

      homeConfigurations = {
        "${myvars.user}" = mkHome "x86_64-linux" {
          profileLevelOver = {
            tuiAdvanced = false;
          };
        };
      };

      systemConfigs = {
        "debnsm" = mkSysMgr "debnsm" {
          system = "x86_64-linux";
          profileLevelOver = {
            tuiAdvanced = true;
            tuiOptional = false;
            guiBase = false;
            guiHeavy = false;
          };
        };
      };

      ## Development Shells
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              git
              just
              nh
              statix
            ];
            name = "devsh";
            shellHook = ''
              echo "Welcome to handy-sun/expnix devshell"
            '';
          };
          sysmgr = pkgs.mkShell {
            packages = with pkgs; [
              just
              nix-output-monitor
              system-manager
            ];
            name = "dev-sysmgr";
            shellHook = ''
              echo "Welcome to handy-sun/expnix sysmgr"
            '';
          };
        }
      );

      ## nix code formatter
      formatter = forFormatterSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rs);
    };
}
