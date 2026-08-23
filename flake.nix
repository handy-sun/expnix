{
  description = "handy-sun NixOS flake configuration";

  # nixConfig = {
  #   bash-prompt = "\\[\\e[0m\\]\\[\\033[0;32m\\]\\A (develop) \\[\\e[0;36m\\]\\w \\[\\e[0m\\]\\\\$\\[\\e[0m\\] ";
  # };

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

    nixpak = {
      url = "github:nixpak/nixpak";
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

    mark-shot = {
      url = "github:jswysnemc/mark-shot";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flyline = {
      url = "github:HalFrgrd/flyline";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## VoCoType-linux: offline Chinese voice input (FunASR) as a global
    ## Fcitx5 module. Pin the tag; its nixpkgs stays self-pinned (validated).
    vocotype = {
      url = "github:LeonardNJU/VocoType-linux/v5.0.1";
    };

    daeuniverse.url = "github:daeuniverse/flake.nix";

    rust-analyzer-mcp-src = {
      url = "github:zeenix/rust-analyzer-mcp";
      flake = false;
    };

    qt-rules-mcp-src = {
      url = "github:lpmwfx/QT-RulesMCP";
      flake = false;
    };

    # Flutter UI 1.4.9 from nixpkgs#541451; use nixpkgs.rustdesk-flutter after it merges.
    rustdesk-flutter-nixpkgs.url = "github:NixOS/nixpkgs/862d3001bcdfed4e93ee565073e2254ad339ebb0";

    ## ------ my applications, configs and scripts ------
    githand = {
      url = "github:handy-sun/githand";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    my-nvimdots = {
      url = "github:handy-sun/nvimdots";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    my-dotzsh = {
      url = "github:handy-sun/dotzsh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    my-dotvim = {
      url = "github:handy-sun/dotvim";
      flake = false;
    };

    my-dotfiles = {
      url = "github:handy-sun/dotfiles";
      flake = false;
    };

    my-wezterm = {
      ## `shallow=1` is rejected by newer Nix (GitHub Actions runners), so
      ## fetch the full tree. It is a tiny flake=false source anyway.
      url = "github:handy-sun/wezterm-config/nix-hm";
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
      myutils = import ./lib/utils.nix {
        inherit inputs;
        inherit (nixpkgs) lib;
      };
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
          profileLevelOver = {
            tuiOptional = true;
          };
          isWSL = true;
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
          devNixConfig = ''
            extra-experimental-features = nix-command flakes
            accept-flake-config = true
            substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store/ https://mirrors.ustc.edu.cn/nix-channels/store
          '';
        in
        {
          default = pkgs.mkShell {
            NIX_CONFIG = devNixConfig;
            packages = with pkgs; [
              vim
              git
              curl
              just
              nh
              nix-output-monitor
              age
              sops
              ssh-to-age
            ];
            name = "devsh";
            shellHook = ''
              echo "Welcome to handy-sun/expnix devshell"
            '';
          };
          sysmgr = pkgs.mkShell {
            NIX_CONFIG = devNixConfig;
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
