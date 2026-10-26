# Single source of truth for the agent skills catalog.
#
# Imported by home-manager.nix (what Home Manager deploys) and by flake.nix
# (the bundle check and the inspection apps), so the deployed set, the
# inspectable set and the checked bundle cannot drift apart.
#
# Only skills listed in skills.enable are deployed: a directory under local/
# stays inert until its ID is listed here.
{ inputs }:
{
  sources = {
    local = {
      path = ./local;
      idPrefix = "local";
    };

    # Skills maintained in TaysiTsuki, consumed as a plain source tree so the
    # canonical copy stays in that repository instead of being forked here.
    taysi = {
      path = inputs.taysi-tsuki;
      subdir = "home/agents/skills";
      idPrefix = "taysi";
    };
  };

  skills = {
    enable = [
      "local/api-and-interface-design"
      "local/autonomous-ai-agents/claude-code"
      "local/autonomous-ai-agents/codex"
      "local/autonomous-ai-agents/opencode"
      "local/awesome-cv-customization"
      "local/browser-testing-with-devtools"
      "local/ci-cd-and-automation-overview"
      "local/ci-cd-and-automation/desktop-app-ci"
      "local/ci-cd-and-automation/desktop-app-qt6-ci"
      "local/ci-cd-and-automation/nix-flake-ci"
      "local/code-review-and-quality-overview"
      "local/code-review-and-quality/cpp-code-review"
      "local/code-simplification"
      "local/context-engineering"
      "local/deprecation-and-migration"
      "local/devops/docker-compose-selfhost"
      "local/devops/hdd-pending-sector-repair"
      "local/devops/kanban-orchestrator"
      "local/devops/kanban-worker"
      "local/devops/webhook-subscriptions"
      "local/documentation-and-adrs"
      "local/domain-name-brainstormer"
      "local/email/himalaya"
      "local/frontend-ui-engineering"
      "local/git-workflow-and-versioning"
      "local/github/codebase-inspection"
      "local/github/github-auth"
      "local/github/github-code-review"
      "local/github/github-issues"
      "local/github/github-pr-workflow"
      "local/github/github-release-management"
      "local/github/github-repo-management"
      "local/idea-refine"
      "local/incremental-implementation"
      "local/leisure/find-nearby"
      "local/mcp/mcporter"
      "local/mcp/native-mcp"
      "local/nix-flake-development"
      "local/nix-module-capability-detection"
      "local/note-taking/obsidian"
      "local/performance-optimization"
      "local/planning-and-task-breakdown"
      "local/release-skills"
      "local/security-and-hardening"
      "local/shell-scripting"
      "local/shipping-and-launch"
      "local/singbox-config"
      "local/skills-nix-maintenance"
      "local/social-media/xurl"
      "local/software-development/adding-rust-enum-variant"
      "local/software-development/c-development"
      "local/software-development/cargo-dependency-update"
      "local/software-development/cc-switch-app-type-wiring"
      "local/software-development/design-md-init"
      "local/software-development/expnix-workflow"
      "local/software-development/node-inspect-debugger"
      "local/software-development/project-docs"
      "local/software-development/python-debugpy"
      "local/software-development/requesting-code-review"
      "local/software-development/rust-pre-commit-hook"
      "local/software-development/rust-struct-field-propagation"
      "local/software-development/rust-test-isolation"
      "local/software-development/spike"
      "local/software-development/subagent-driven-development"
      "local/software-development/systematic-debugging"
      "local/software-development/writing-plans"
      "local/source-driven-development"
      "local/spec-driven-development"
      "local/test-driven-development"
      "local/using-agent-skills"
      "local/web-access"
      "local/workflow-skill-architect"
      "taysi/chinese-prose-lint"
      "taysi/code-cultivation"
      "taysi/group-meeting"
      "taysi/handoff"
      "taysi/host-system-convention"
      "taysi/humanizer"
      "taysi/prune-comments-and-docs"
      "taysi/sillytavern-card-backup"
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
  # (${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills etc.): Home Manager activation
  # runs from home-manager-<user>.service, whose environment does not carry
  # CLAUDE_CONFIG_DIR or CODEX_HOME, so the defaults would expand to ~/.claude
  # and ~/.codex while the agents read the XDG paths set in
  # home/default.nix's sessionVariables.
  targets = {
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
