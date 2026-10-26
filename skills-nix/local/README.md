# local/

Skills maintained in this repository. Every directory containing a `SKILL.md`
is a skill; nesting a directory adds a `/`-separated level to its ID, so
`local/software-development/expnix-workflow/SKILL.md` becomes
`local/software-development/expnix-workflow` because the source uses
`idPrefix = "local"`.

Adding a file here does not deploy it. List the ID in `../catalog.nix` under
`skills.enable` (or `skills.explicit` when the skill is limited to some
agents). Skills installed on every enabled target belong in `skills.enable`.

Front matter follows the Agent Skills convention:

```markdown
---
name: expnix-workflow
description: When to use this skill and what it covers.
---
```

Keep references and scripts beside `SKILL.md`; the whole directory is linked
into the bundle. A skill directory must not contain another skill: the bundle
materializes each skill as a symlink to its directory, so a parent skill and a
child skill cannot share a path. Category directories are fine as long as they
have no `SKILL.md` of their own (the two overview skills live in
`<category>-overview/` for that reason).
