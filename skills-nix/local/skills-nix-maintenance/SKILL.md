---
name: skills-nix-maintenance
description: Maintains the agent skill catalog in this expnix checkout. Use when adding, renaming or removing a skill under skills-nix/, when wiring an upstream skill repository, when updating skills-nix/flake.lock, or when an agent cannot see a skill that should be deployed.
---

# skills-nix maintenance

`skills-nix/` is the only writer for the skill directories Nix owns:

| Target | Directory |
| --- | --- |
| agents | `$HOME/.agents/skills` (the directory dsh reads as its user-agents root) |
| claude | `$HOME/.config/claude/skills` |
| codex | `$HOME/.config/codex/skills` |
| opencode / omp | `$HOME/.config/opencode/skills` |

Hermes is not managed: `$HERMES_HOME/skills` also holds bundled skills,
curator state and user edits. The claude and codex destinations are literal
paths rather than the module defaults because Home Manager activation runs
from `home-manager-<user>.service`, which has no `CLAUDE_CONFIG_DIR` or
`CODEX_HOME` in its environment.

## Files

| File | Role |
| --- | --- |
| `catalog.nix` | sources, selected skill IDs, enabled targets |
| `local/` | skills with no upstream, one flat directory each |
| `home-manager.nix` | module body; enables `programs.agent-skills` from the catalog |
| `flake.nix` | upstream inputs, apps (`skills-list`, `skills-install`), bundle package, check |

## Rules

- **Flat layout.** No `idPrefix` and no category directories. Every deployed
  skill is `<dest>/<name>/SKILL.md`. Some agents scan only one level below
  their skills root, so a nested ID is invisible to them.
- **Upstream first.** A skill that exists in a public repository is taken from
  that repository as a flake input; `local/` holds only what has no upstream.
- **Selection only.** Nothing is deployed unless it is listed in
  `skills.enable` (or `skills.explicit`).

## Add or change a skill

1. If it has an upstream, add the repository to `skills-nix/flake.nix` as a
   `flake = false` input and declare the source in `catalog.nix`
   (`subdir` / `filter.nameRegex` as needed).
2. If the upstream layout is nested, select the skill through
   `skills.explicit`; the declaration name becomes the deployed name, which
   keeps the target flat:

   ```nix
   explicit.python-debugpy = {
     from = "some-nested-source";
     path = "software-development/python-debugpy";
   };
   ```

   Otherwise add the flat ID to `skills.enable`.
3. Only project-specific skills go to `local/<name>/SKILL.md`; they still need
   their ID in `skills.enable`.
4. `git add` the new files. Flake evaluation only sees tracked files, so an
   untracked skill stays invisible.
5. Inspect and check:

   ```bash
   nix run ./skills-nix#skills-list | jq -r 'keys[]'
   nix build ./skills-nix && find -L result -name SKILL.md | sort
   nix flake check ./skills-nix
   ```

6. Deploy on a host listed in `catalog.nix` (`just s`; `just sysmgr` on
   system-manager hosts).

To deploy a skill to some agents only, add `agents = [ "codex" ];` to its
explicit declaration. Skills selected through `skills.enable` go to every
enabled target.

## Locks

- `skills-nix/flake.lock` pins nixpkgs, agent-skills-nix and the three skill
  repositories: `cd skills-nix && nix flake update`.

After either update, run `nix flake check ./skills-nix`, review the skill
diff, then switch. Never sync an unreviewed lock.

## Guard rails

- Do not set `AGENT_SKILLS_FORCE=1` against a real agent directory before
  confirming where every existing entry came from. The synchronizer refuses
  non-empty directories without `.agent-skills-managed.json` for that reason.
- Do not point any target at `$HERMES_HOME/skills`.
- `cc-switch-tui` must stay in `skills.mode = "external"`; two writers on one
  directory overwrite each other.
- `nix run ./skills-nix#skills-install` writes the real target directories.
  Use `AGENT_SKILLS_DESTS=/tmp/skills-preview` for an inspection run.
