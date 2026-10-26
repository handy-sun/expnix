---
name: skills-nix-maintenance
description: Maintains the agent skill catalog in this expnix checkout. Use when adding, renaming, restricting or removing a skill under skills-nix/, when updating skills-nix/flake.lock or the source registry lock, or when an agent cannot see a skill that should be deployed.
---

# skills-nix maintenance

`skills-nix/` is the only writer for the skill directories Nix owns:

| Target | Directory |
| --- | --- |
| claude | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills` |
| codex | `${CODEX_HOME:-$HOME/.codex}/skills` |
| opencode / omp | `$HOME/.config/opencode/skills` |
| gemini | `$HOME/.gemini/skills` |

Hermes is not managed: `$HERMES_HOME/skills` also holds bundled skills,
curator state and user edits.

## Files

| File | Role |
| --- | --- |
| `catalog.nix` | sources, selected skill IDs, enabled targets |
| `local/` | skills maintained in this repository |
| `home-manager.nix` | module body; enables `programs.agent-skills` from the catalog |
| `registry/` | upstream repositories pinned by a generated lock instead of a flake input |
| `flake.nix` | apps (`skills-list`, `skills-install`, `skills-sources-lock`), bundle package, check |

## Add or change a skill

1. Create `local/<category>/<skill>/SKILL.md` with `name` and `description`
   front matter.
2. Add its ID (`local/<category>/<skill>`) to `skills.enable` in
   `catalog.nix`. Unlisted directories are not deployed.
3. `git add` the new files. Flake evaluation only sees tracked files, so an
   untracked skill stays invisible.
4. Inspect and check:

   ```bash
   nix run ./skills-nix#skills-list | jq -r 'keys[]'
   nix build ./skills-nix && ls -R result/
   nix flake check ./skills-nix
   ```

5. Deploy with `just switch-home`.

To deploy a skill to some agents only, select it through `skills.explicit`
instead of `skills.enable`:

```nix
skills.explicit.omp-workflow = {
  from = "local";
  path = "agents/omp-workflow";
  agents = [ "opencode" ];
};
```

## Locks

Two independent locks:

- `skills-nix/flake.lock` pins flake sources and the agent-skills-nix
  revision: `nix flake update --flake ./skills-nix`.
- `skills-nix/registry/sources.lock.json` pins registry sources:
  `cd skills-nix && nix run .#skills-sources-lock`.

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
