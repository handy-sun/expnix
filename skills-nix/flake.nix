{
  description = "Agent skills catalog for expnix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Upstream skill collections. All of them are consumed as plain source
    # trees (`flake = false`): the repositories own the content, this catalog
    # only selects which skills are deployed. hermes-agent is a whole agent
    # runtime (~271 MB), needed because twelve skills live only there.
    addyosmani-skills = {
      url = "github:addyosmani/agent-skills";
      flake = false;
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      flake = false;
    };

    browser-act-skills = {
      url = "github:browser-act/skills";
      flake = false;
    };

    taysi-tsuki = {
      url = "github:MidAutumnMoon/TaysiTsuki";
      flake = false;
    };
  };

  outputs =
    inputs@{ nixpkgs, agent-skills, ... }:
    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;

      agentLib = agent-skills.lib.agent-skills;

      catalog = import ./catalog.nix { inherit inputs; };
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
          # The selection, not the full catalog: the question this app answers
          # is "what will be deployed".
          selectionJson = pkgs.writeText "expnix-agent-skills-selection.json" (
            builtins.toJSON (agentLib.catalogJson selection)
          );
        in
        pkgs.writeShellApplication {
          name = "skills-list";
          runtimeInputs = [ pkgs.jq ];
          text = ''
            ${pkgs.jq}/bin/jq . ${selectionJson}
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
            meta.description = "Print the enabled expnix agent skills as JSON";
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
