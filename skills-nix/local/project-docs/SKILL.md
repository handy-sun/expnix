---
name: project-docs
description: Maintain project documentation — CLAUDE.md generation, bilingual READMEs, and docs sync. Use when initializing project context files, adding sections to multilingual docs, or keeping paired READMEs in sync.
---

# Project Documentation

Maintain project context files and multilingual documentation.

## CLAUDE.md / Project Init

When a project has no CLAUDE.md (or equivalent rules file), generate one by scanning:

1. **Build config** — `Cargo.toml`, `package.json`, `Makefile`, `pyproject.toml`
2. **Build scripts** — `build.rs`, `setup.py`, custom build steps
3. **CI workflows** — `.github/workflows/*.yml`, `.gitlab-ci.yml`
4. **Source tree** — `src/`, `lib/`, module structure
5. **Git config** — branch strategy, commit conventions
6. **Platform notes** — OS requirements, permissions, deployment targets

### CLAUDE.md Template

```markdown
# <project-name>

<one-line description>

## Build
<build commands — debug, release, specific targets>

## Test / Lint
<test, lint, format check commands>

## Architecture
<module-by-module breakdown with one-line descriptions>

## Key Dependencies
<table of major crates/packages/libs with purpose>

## Platform
<target OS, permissions, deployment notes>

## Git Workflow
<branch strategy, CI triggers, commit format>

## Conventions
<coding style, error handling patterns, user preferences>
```

### Principles

- **Don't create AGENTS.md unless asked** — some users only want CLAUDE.md
- Scan actual files, don't guess at project structure
- Include build commands the user actually uses (check Makefile, scripts)
- Note cross-compilation targets if CI tests them
- Record the user's commit message format if visible in git log

## Bilingual / Multilingual README Maintenance

When a project maintains paired READMEs (e.g. `README.md` + `README.zh-CN.md`):

### Adding a New Section

1. **Read both files fully first** — understand the existing structure, TOC format, and section numbering
2. **Add to both files in the same pass** — don't do one language first and forget the other
3. **Maintain parallel structure** — sections must appear in the same order in both files
4. **Update both TOCs** — if the files have table of contents, add the new entry to both
5. **Watch for orphaned headers** — if inserting between an existing section's header and its content (e.g. a Todo section whose items are further down), the old header becomes orphaned. Move it to the correct position

### Section Ordering Pitfall

When inserting a new section between existing sections, the patch tool may leave an old header in place above the new section while its content remains below. Result: orphaned header at line N, new section at line N+1, old section's content at line N+80. **Always verify final section order** by grepping for `^##` headers after patching.

**The numbering problem is separate from the ordering problem.** Even after fixing order, section numbers may be wrong (e.g. Todo labeled "## 3" appearing after Lua labeled "## 4"). Fix approach:
1. First patch to insert the new section at the right position (may create orphaned header + wrong numbering)
2. Then do a second patch to: remove orphaned old header, re-add it after new section content, fix all section numbers
3. Verify with `grep '^## ' file` — numbers must be sequential and headers must appear in the same order as the TOC

### Content Translation Approach

- Write one language fully, then translate to the other
- Keep code blocks identical across languages (same commands, same output)
- Translate prose, descriptions, and explanations — not variable names or technical terms
- Link format: `README.md` links to `README.zh-CN.md` and vice versa at the top

### Sync Checklist

After editing bilingual docs:
- [ ] Both files have the same number of top-level sections
- [ ] Sections appear in the same order in both files
- [ ] Both TOCs are updated
- [ ] No orphaned `##` headers exist (header with no body before the next header)
- [ ] Code blocks are identical across languages
