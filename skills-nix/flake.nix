{
  description = "Agent skills catalog for expnix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, agent-skills, ... }:
    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;

      agentLib = agent-skills.lib.agent-skills;

      catalog = import ./catalog.nix;
      discovered = agentLib.discoverCatalog catalog.sources;
      allowlist = agentLib.allowlistFor {
        catalog = discovered;
        inherit (catalog) sources;
        inherit (catalog.skills) enable enableAll;
      };
      selection = agentLib.selectSkills {
        catalog = discovered;
        inherit allowlist;
        inherit (catalog) sources;
        skills = catalog.skills.explicit;
      };

      bundleFor =
        system:
        agentLib.mkBundle {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit selection;
          name = "expnix-agent-skills";
        };

      # Merge the catalog's target switches onto the upstream defaults, so the
      # install app serializes complete target records (dest, structure).
      syncTargets = lib.mapAttrs (
        name: target: (agentLib.defaultTargets.${name} or { }) // target
      ) catalog.targets;

      listProgramFor =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          catalogJson = pkgs.writeText "expnix-agent-skills-catalog.json" (
            builtins.toJSON (agentLib.catalogJson discovered)
          );
        in
        pkgs.writeShellApplication {
          name = "skills-list";
          runtimeInputs = [ pkgs.jq ];
          text = ''
            ${pkgs.jq}/bin/jq . ${catalogJson}
          '';
        };
    in
    {
      homeManagerModules.default = {
        imports = [
          agent-skills.homeManagerModules.default
          (import ./home-manager.nix { inherit catalog; })
        ];
      };

      packages = forAllSystems (system: {
        default = bundleFor system;
      });

      checks = forAllSystems (system: {
        # nix flake check ./skills-nix builds the selected bundle.
        default = bundleFor system;
      });

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          installProgram = agentLib.mkSyncProgram {
            inherit pkgs;
            bundle = bundleFor system;
            targets = syncTargets;
            allowOverrides = true;
          };
        in
        {
          skills-list = {
            type = "app";
            program = "${listProgramFor system}/bin/skills-list";
            meta.description = "Print the selected expnix agent skills as JSON";
          };

          skills-install = {
            type = "app";
            program = "${installProgram}/bin/skills-install";
            meta.description = "Sync the selected skills into the enabled target directories";
          };

          # Must run inside skills-nix/: the program resolves
          # registry/sources relative to the current directory.
          skills-sources-lock = {
            type = "app";
            program = "${agentLib.mkSourceLockProgram { inherit pkgs; }}/bin/skills-sources-lock";
            meta.description = "Refresh registry/sources.lock.json from registry/sources/*.nix";
          };
        }
      );
    };
}
