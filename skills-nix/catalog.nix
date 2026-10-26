# Single source of truth for the agent skills catalog.
#
# Imported by home-manager.nix (what Home Manager deploys) and by flake.nix
# (the bundle check and the inspection apps), so the deployed set, the
# inspectable set and the checked bundle cannot drift apart.
#
# Only skills listed in skills.enable are deployed: a directory under local/
# stays inert until its ID is listed here.
{
  sources = {
    local = {
      path = ./local;
      idPrefix = "local";
    };
  };

  skills = {
    enable = [
      "local/skills-nix-maintenance"
      "local/software-development/expnix-workflow"
    ];
    enableAll = false;
    explicit = { };
  };

  # Hosts that receive the global skill directories, matched against
  # `hostName`. A standalone Home Manager activation carries no host name and
  # is skipped, as are servers that have no agent to read these directories.
  hosts = [
    "buking"
    "handyMini"
  ];

  # OpenCode and OMP share one directory because omp resolves
  # ~/.config/opencode/skills. Hermes is intentionally absent: its skills root
  # mixes bundled skills, curator state and user edits.
  targets = {
    claude.enable = true;
    codex.enable = true;
    opencode.enable = true;
    gemini.enable = true;
  };
}
