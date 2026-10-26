# Single source of truth for the agent skills catalog.
#
# Imported by home-manager.nix (what Home Manager deploys) and by flake.nix
# (the bundle check and the inspection apps), so the deployed set, the
# inspectable set and the checked bundle cannot drift apart.
#
# No source sets `idPrefix`: every skill ID is a single directory name, so a
# target ends up as <dest>/<name>/SKILL.md. Some agents only scan one level
# below their skills root (dsh reads ~/.dsh/skills/<name>/SKILL.md and
# ~/.agents/skills/<name>/SKILL.md), so anything deeper is invisible to them.
{ inputs }:
{
  sources = {
    # Upstream collections, consumed as plain source trees. Their layout is
    # untouched; the selection below decides what is deployed.
    addyosmani = {
      path = inputs.addyosmani-skills;
      subdir = "skills";
    };

    browser-act = {
      path = inputs.browser-act-skills;
      filter.nameRegex = "^browser-act$";
    };

    taysi = {
      path = inputs.taysi-tsuki;
      subdir = "home/agents/skills";
    };

    # Skills maintained in this repository, including the Hermes toolkit skills
    # that were copied out of its 271 MB runtime repository.
    local = {
      path = ./local;
    };
  };

  skills = {
    enable = [
      # addyosmani/agent-skills
      "api-and-interface-design"
      "browser-testing-with-devtools"
      "ci-cd-and-automation"
      "code-review-and-quality"
      "code-simplification"
      "context-engineering"
      "deprecation-and-migration"
      "documentation-and-adrs"
      "frontend-ui-engineering"
      "git-workflow-and-versioning"
      "idea-refine"
      "incremental-implementation"
      "performance-optimization"
      "planning-and-task-breakdown"
      "security-and-hardening"
      "shipping-and-launch"
      "source-driven-development"
      "spec-driven-development"
      "test-driven-development"
      "using-agent-skills"
      # browser-act/skills
      "browser-act"
      # TaysiTsuki (home/agents/skills)
      "challenge-architecture"
      "chinese-prose-lint"
      "code-cultivation"
      "group-meeting"
      "handoff"
      "host-system-convention"
      "humanizer"
      "naming-and-magic-literals"
      "post-impl-housekeep"
      "prune-comments-and-docs"
      "sillytavern-card-backup"
      # local/
      "adding-rust-enum-variant"
      "awesome-cv-customization"
      "c-development"
      "cargo-dependency-update"
      "codebase-inspection"
      "cpp-code-review"
      "design-md-init"
      "desktop-app-ci"
      "desktop-app-qt6-ci"
      "docker-compose-selfhost"
      "domain-name-brainstormer"
      "expnix-workflow"
      "find-nearby"
      "github-auth"
      "github-code-review"
      "github-issues"
      "github-pr-workflow"
      "github-release-management"
      "github-repo-management"
      "hdd-pending-sector-repair"
      "mcporter"
      "nix-flake-ci"
      "nix-flake-development"
      "nix-module-capability-detection"
      "node-inspect-debugger"
      "obsidian"
      "project-docs"
      "python-debugpy"
      "release-skills"
      "requesting-code-review"
      "rust-pre-commit-hook"
      "rust-struct-field-propagation"
      "rust-test-isolation"
      "shell-scripting"
      "skills-nix-maintenance"
      "spike"
      "systematic-debugging"
      "workflow-skill-architect"
      "writing-plans"
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
  #
  # claude and codex get explicit destinations instead of the module defaults
  # (CLAUDE_CONFIG_DIR / CODEX_HOME fallbacks): Home Manager activation runs
  # from home-manager-<user>.service, whose environment does not carry those
  # variables, so the defaults would expand to ~/.claude and ~/.codex while the
  # agents read the XDG paths set in home/default.nix's sessionVariables.
  #
  # agents is the shared `$HOME/.agents/skills` directory. dsh reads it as its
  # user-agents root, which is how these skills reach dsh at all.
  targets = {
    agents.enable = true;
    claude = {
      dest = "$HOME/.config/claude/skills";
      enable = true;
    };
    codex = {
      dest = "$HOME/.config/codex/skills";
      enable = true;
    };
    opencode.enable = true;
    gemini.enable = true;
  };
}
