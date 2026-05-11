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

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    nixfmt-rs.url = "github:Mic92/nixfmt-rs";
    ## This flake is only built and tested against its pinned nixpkgs-unstable input.
    llm-agents.url = "github:numtide/llm-agents.nix";

    ## ------ my configs and scripts ------
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
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      myvars = import ./lib/vars.nix;
      myutils = import ./lib/utils.nix { inherit (nixpkgs) lib; };

      mkHome = import ./lib/mkhome.nix {
        inherit
          nixpkgs
          inputs
          myvars
          myutils
          ;
      };

      mkSystem = import ./lib/mksystem.nix {
        inherit
          nixpkgs
          inputs
          self
          myvars
          myutils
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
        "${myvars.user}" = mkHome "x86_64-linux" { };
      };

      ##  Development Shells
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
              _bash_prompt_cmd() {
                local lastStatus=$?
                local promFg
                [[ $lastStatus -eq 0 ]] && promFg="92" || promFg="91"
                PS1="\[\e[0m\]\[\033[0;32m\]\A ($name) \[\e[0;36m\]\w \[\e[0;''${promFg}m\]\\$\[\e[0m\] "
              }
              export PROMPT_COMMAND=_bash_prompt_cmd
              echo "Welcome to handy-sun/expnix devshell"
            '';
          };
        }
      );

      ## nix code formatter
      formatter = forAllSystems (
        system:
        inputs.treefmt-nix.lib.mkWrapper nixpkgs.legacyPackages.${system} {
          programs.nixfmt = {
            enable = true;
            package = inputs.nixfmt-rs.packages.${system}.default;
          };
        }
      );
    };
}
