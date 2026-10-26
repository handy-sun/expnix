---
name: github-release-management
description: Manage GitHub releases triggered by tag pushes. Use when creating, re-triggering, fixing, or publishing GitHub releases. Covers release workflow patterns, asset management, draft handling, and troubleshooting missing artifacts.
tags: [github, release, ci, workflow]
---

# GitHub Release Management

Manage GitHub releases that are triggered by tag pushes, including troubleshooting incomplete releases and coordinating with CI workflows.

## Core Principles

1. **Respect CI defaults** — if the workflow creates draft releases, leave them as drafts unless the user explicitly asks to publish.
2. **Confirm before destructive operations** — always confirm before deleting tags, releases, or re-triggering workflows.
3. **Verify asset completeness** — after a release workflow completes, check that all expected assets are present.

## Standard Release Flow

```
Version bump in source (Cargo.toml, package.json, etc.)
  → Commit
  → Tag on the version bump commit
  → Push tag
  → CI workflow builds + creates draft release
  → Verify assets
  → (Optional) Publish if user requests
```

## Re-triggering a Release Workflow

When a workflow already ran on a tag and you need to re-trigger:

```bash
# 1. Delete existing release(s)
gh release delete <tag> --yes
# Repeat if duplicates exist — check with gh release list

# 2. Delete local + remote tag
git tag -d <tag>
git push origin --delete <tag>

# 3. Recreate tag on correct commit
git tag <tag>
git push origin <tag>

# 4. Monitor
gh run list --workflow=<workflow>.yml --limit=1
gh run watch <run_id>
```

## Tag-Commit Alignment

**The tag must point to the commit where the version file has the correct version.** If the tag was created before the version bump, artifacts will have the wrong version number.

Always verify:
```bash
git rev-parse <tag>   # Should equal the version bump commit
git rev-parse HEAD
```

## Troubleshooting Missing Assets

### Parallel Job Race Condition

With `softprops/action-gh-release` and matrix builds (parallel jobs), each job independently manages the release. If the release doesn't exist when multiple jobs finish simultaneously, each creates its own — only the last one survives, losing other assets.

**Symptoms**: Release has fewer assets than build targets. All jobs report success.

**Fix**:
1. List all workflow artifacts:
   ```bash
   gh api repos/{owner}/{repo}/actions/runs/{run_id}/artifacts --jq '.artifacts[] | "\(.id) \(.name)"'
   ```
2. Compare with release assets: `gh release view <tag>`
3. Download missing artifacts (they're **ZIP-wrapped**):
   ```bash
   gh api "repos/{owner}/{repo}/actions/artifacts/{id}/zip" > tmp.zip
   unzip tmp.zip -d tmp/
   # Inner file is the actual release archive (.tar.gz, .zip, etc.)
   ```
4. Upload to release:
   ```bash
   gh release upload <tag> tmp/inner-file.tar.gz
   ```

### Prevention

Use a separate upload job that `needs:` all build jobs, so the release is created only once with all assets ready.

## Workflow Without `workflow_dispatch`

If a release workflow only supports `release` and `push tags` triggers (no `workflow_dispatch`), you can only re-trigger by pushing a new tag. You cannot manually trigger it via `gh workflow run`.

## Commands Reference

| Task | Command |
|------|---------|
| List releases | `gh release list` |
| View release | `gh release view <tag>` |
| Delete release | `gh release delete <tag> --yes` |
| Delete release + local tag (careful!) | `gh release delete <tag> --yes --cleanup-tag` |

**Pitfall**: `--cleanup-tag` deletes both the GitHub release AND the local git tag. For most re-trigger cases, use `gh release delete <tag> --yes` + `git push origin --delete <tag>` separately so the local tag survives.
| Publish draft | `gh release edit <tag> --draft=false` |
| Upload asset | `gh release upload <tag> <file>` |
| List workflow runs | `gh run list --workflow=<name>.yml` |
| View run details | `gh run view <run_id>` |
| Watch run | `gh run watch <run_id>` |
| List run artifacts | `gh api repos/{o}/{r}/actions/runs/{id}/artifacts` |

See `references/artifact-recovery.md` for step-by-step asset recovery examples.
