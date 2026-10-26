---
name: rust-pre-commit-hook
description: "Set up a git pre-commit hook for Rust projects that runs rustfmt on staged .rs files. Auto-fixes on failure and blocks commit. Use when adding formatting enforcement to a Rust project without CI overhead."
tags: [rust, git, hooks, rustfmt, pre-commit, formatting]
---

# Rust Pre-commit Hook (rustfmt)

Local git hook that enforces `rustfmt` on staged `.rs` files before each commit. Blocks the commit if formatting issues are found, auto-corrects them, and asks the user to re-stage.

## When to Use

- Rust project needs formatting enforcement but CI fmt check is overkill or removed
- User wants local-only formatting gate (no CI round-trip)
- Replacing a CI `cargo fmt --check` job with a local hook

## Setup

### 1. Create `.githooks/pre-commit`

```bash
mkdir -p .githooks
```

```bash
cat > .githooks/pre-commit << 'EOF'
#!/bin/bash

echo "Checking Rust code format ..."
has_issues=0
edition=2021

for file in $(git diff --name-only --staged | grep '\.rs$'); do
    if [ -f "${file}" ] && ! rustfmt --edition ${edition} --check --color auto "${file}"; then
        echo ""
        has_issues=1
        rustfmt --edition ${edition} "${file}"
    fi
done

if [ ${has_issues} -eq 0 ]; then
    exit 0
fi

echo "Your code contains formatting issues and has been corrected. Please run \`git add\` to add them and commit them."
exit 1
EOF

chmod +x .githooks/pre-commit
```

### 2. Configure git to use `.githooks/`

```bash
git config core.hooksPath .githooks
```

### 3. If removing from CI

Remove the `fmt` job and any `needs: fmt` dependencies from other jobs in the workflow file.

## Key Design Decisions

- **Staged files only** — `git diff --name-only --staged` avoids formatting unrelated files
- **Auto-fix + block** — runs `rustfmt` to fix, then exits 1 so user reviews and re-adds
- **Edition from Cargo.toml** — check `src-tauri/Cargo.toml` or root `Cargo.toml` for `edition = "..."`, use that value in the hook
- **`core.hooksPath`** — project-local config (not global), stored in `.git/config` automatically

## Pitfalls

1. **Edition mismatch** — hook uses `edition=2021` but project might use `2024` or `2018`. Always check `Cargo.toml` first.
2. **Multi-crate workspace** — if the project has multiple `Cargo.toml` files with different editions, the simple per-file approach won't work. Consider using `cargo fmt --check` at workspace root instead.
3. **`core.hooksPath` is per-repo** — it's set in `.git/config`, not committed. New clones need to run `git config core.hooksPath .githooks` again. Consider documenting in CONTRIBUTING.md or adding to a setup script.
4. **macOS `sed -i`** — if the hook ever needs `sed -i`, remember to use `sed -i ''` on macOS (not directly relevant to this hook but a common trap in git hooks).
