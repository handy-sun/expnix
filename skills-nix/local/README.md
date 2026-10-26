# local/

Skills maintained in this repository. Every skill is one directory with a
`SKILL.md` at the top of `local/`:

```text
local/
├── nix-flake-development/SKILL.md
├── rust-test-isolation/SKILL.md
└── ...
```

Two rules:

- **Flat only.** No category directories and no skill inside another skill.
  The deployed tree mirrors the source layout, and several agents only scan one
  level below their skills root, so a nested layout would be invisible to them.
  Keep the category in the file name (`rust-test-isolation`) or in the front
  matter instead.
- **Upstream first.** If the skill exists in a public repository, wire that
  repository up in `../catalog.nix` instead of copying the content here. Local
  copies are for project-specific skills with no upstream.

Front matter follows the Agent Skills convention:

```markdown
---
name: rust-test-isolation
description: When to use this skill and what it covers.
---
```

Keep references and scripts beside `SKILL.md`; the whole directory is linked
into the bundle.
