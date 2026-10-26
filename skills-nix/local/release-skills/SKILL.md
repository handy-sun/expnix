---
name: release-skills
description: Universal release workflow. Auto-detects version files and changelogs. Supports Node.js, Python, Rust, Claude Plugin, and generic projects. Use when user says "release", "发布", "new version", "bump version", "push", "推送", "publish to crates.io", "cargo publish".
---

# Release Skills

Universal release workflow supporting any project type with multi-language changelog.

## User Input Tools

When this skill prompts the user, follow this tool-selection rule (priority order):

1. **Prefer built-in user-input tools** exposed by the current agent runtime — e.g., `AskUserQuestion`, `request_user_input`, `clarify`, `ask_user`, or any equivalent.
2. **Fallback**: if no such tool exists, emit a numbered plain-text message and ask the user to reply with the chosen number/answer for each question.
3. **Batching**: if the tool supports multiple questions per call, combine all applicable questions into a single call; if only single-question, ask them one at a time in priority order.

Concrete `AskUserQuestion` references below are examples — substitute the local equivalent in other runtimes.

## Quick Start

Just run `/release-skills` - auto-detects your project configuration.

## Supported Projects

| Project Type | Version File | Auto-Detected |
|--------------|--------------|---------------|
| Node.js | package.json | ✓ |
| Python | pyproject.toml | ✓ |
| Rust | Cargo.toml | ✓ |
| Claude Plugin | marketplace.json | ✓ |
| Generic | VERSION / version.txt | ✓ |

## Options

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview changes without executing |
| `--major` | Force major version bump |
| `--minor` | Force minor version bump |
| `--patch` | Force patch version bump |

## Rust / crates.io Release

When publishing a Rust crate to crates.io and triggering a GitHub Actions release:

1. **Version in Cargo.toml must match the target tag** — update `Cargo.toml` version, commit, then tag. If the tag was created before the version bump, delete and recreate it on the correct commit.
2. **`cargo publish` requires a clean working tree** — commit Cargo.toml + Cargo.lock changes before publishing. Use `CARGO_REGISTRY_TOKEN=<token> cargo publish`.
3. **Release workflows may create draft releases** — check with `gh release view <tag>` and publish with `gh release edit <tag> --draft=false`.
4. **Tag cannot be re-triggered without deletion** — if the workflow already ran on a tag, you must `git tag -d <tag>` + `git push origin --delete <tag>`, recreate, and push again.
5. **Dry-run first** — always `cargo publish --dry-run` to verify packaging before the real upload.

See `references/rust-crates-io-release.md` for the full step-by-step workflow with examples.

## Workflow

### Step 1: Detect Project Configuration

1. Check for `.releaserc.yml` (optional config override)
   - If present, inspect whether it defines release hooks
2. Auto-detect version file by scanning (priority order):
   - `package.json` (Node.js)
   - `pyproject.toml` (Python)
   - `Cargo.toml` (Rust)
   - `marketplace.json` or `.claude-plugin/marketplace.json` (Claude Plugin)
   - `VERSION` or `version.txt` (Generic)
3. Scan for changelog files using glob patterns:
   - `CHANGELOG*.md`
   - `HISTORY*.md`
   - `CHANGES*.md`
4. Identify language of each changelog by filename suffix
5. Display detected configuration

**Project Hook Contract**:

If `.releaserc.yml` defines `release.hooks`, keep the release workflow generic and delegate project-specific packaging/publishing to those hooks.

Supported hooks:

| Hook | Purpose | Expected Responsibility |
|------|---------|-------------------------|
| `prepare_artifact` | Make one target releasable | Validate the target is self-contained, sync/embed local dependencies, optionally stage extra files |
| `publish_artifact` | Publish one releasable target | Upload the prepared target (or a staged directory if the project uses one), attach version/changelog/tags |

Supported placeholders:

| Placeholder | Meaning |
|-------------|---------|
| `{project_root}` | Absolute path to repository root |
| `{target}` | Absolute path to the module/skill being released |
| `{artifact_dir}` | Absolute path to a temporary staging directory for this target, when the project uses one |
| `{version}` | Version selected by the release workflow |
| `{dry_run}` | `true` or `false` |
| `{release_notes_file}` | Absolute path to a UTF-8 file containing release notes/changelog text |

Execution rules:
- Keep the skill generic: do not hardcode registry/package-manager/project layout details into this SKILL.
- If `prepare_artifact` exists, run it once per target before publish-related checks that need the final releasable target state.
- Write release notes to a temp file and pass that file path to `publish_artifact`; do not inline multiline changelog text into shell commands.
- If hooks are absent, fall back to the default project-agnostic release workflow.

**Language Detection Rules**:

Changelog files follow the pattern `CHANGELOG_{LANG}.md` or `CHANGELOG.{lang}.md`, where `{lang}` / `{LANG}` is a language or region code.

| Pattern | Example | Language |
|---------|---------|----------|
| No suffix | `CHANGELOG.md` | en (default) |
| `_{LANG}` (uppercase) | `CHANGELOG_CN.md`, `CHANGELOG_JP.md` | Corresponding language |
| `.{lang}` (lowercase) | `CHANGELOG.zh.md`, `CHANGELOG.ja.md` | Corresponding language |
| `.{lang-region}` | `CHANGELOG.zh-CN.md` | Corresponding region variant |

Common language codes: `zh` (Chinese), `ja` (Japanese), `ko` (Korean), `de` (German), `fr` (French), `es` (Spanish).

### Step 2: Analyze Changes Since Last Tag

```bash
LAST_TAG=$(git tag --sort=-v:refname | head -1)
git log ${LAST_TAG}..HEAD --oneline
git diff ${LAST_TAG}..HEAD --stat
```

Categorize by conventional commit types:

| Type | Description |
|------|-------------|
| feat | New features |
| fix | Bug fixes |
| docs | Documentation |
| refactor | Code refactoring |
| perf | Performance improvements |
| test | Test changes |
| style | Formatting, styling |
| chore | Maintenance (skip in changelog) |

**Breaking Change Detection**:
- Commit message starts with `BREAKING CHANGE`
- Commit body/footer contains `BREAKING CHANGE:`
- Removed public APIs, renamed exports, changed interfaces

If breaking changes detected, warn user: "Breaking changes detected. Consider major version bump (--major flag)."

### Step 3: Determine Version Bump

Rules (in priority order):
1. User flag `--major/--minor/--patch` → Use specified
2. BREAKING CHANGE detected → Major bump (1.x.x → 2.0.0)
3. `feat:` commits present → Minor bump (1.2.x → 1.3.0)
4. Otherwise → Patch bump (1.2.3 → 1.2.4)

Display version change: `1.2.3 → 1.3.0`

### Step 4: Generate Multi-language Changelogs

For each detected changelog file:

1. **Identify language** from filename suffix
2. **Detect third-party contributors**:
   - Check merge commits: `git log ${LAST_TAG}..HEAD --merges --pretty=format:"%H %s"`
   - For each merged PR, identify the PR author via `gh pr view <number> --json author --jq '.author.login'`
   - Compare against repo owner (`gh repo view --json owner --jq '.owner.login'`)
   - If PR author ≠ repo owner → third-party contributor
3. **Generate content in that language**:
   - Section titles in target language
   - Change descriptions written naturally in target language (not translated)
   - Date format: YYYY-MM-DD (universal)
   - **Third-party contributions**: Append contributor attribution `(by @username)` to the changelog entry
4. **Insert at file head** (preserve existing content)

**Section Title Translations** (built-in):

| Type | en | zh | ja | ko | de | fr | es |
|------|----|----|----|----|----|----|-----|
| feat | Features | 新功能 | 新機能 | 새로운 기능 | Funktionen | Fonctionnalités | Características |
| fix | Fixes | 修复 | 修正 | 수정 | Fehlerbehebungen | Corrections | Correcciones |
| docs | Documentation | 文档 | ドキュメント | 문서 | Dokumentation | Documentation | Documentación |
| refactor | Refactor | 重构 | リファクタリング | 리팩토링 | Refactoring | Refactorisation | Refactorización |
| perf | Performance | 性能优化 | パフォーマンス | 성능 | Leistung | Performance | Rendimiento |
| breaking | Breaking Changes | 破坏性变更 | 破壊的変更 | 주요 변경사항 | Breaking Changes | Changements majeurs | Cambios importantes |

### Step 5: Commit, Tag, Push

1. Stage version and changelog files
2. Create release commit: `chore: release v{VERSION}`
3. Create tag: `git tag v{VERSION}`
4. Push if user confirmed: `git push origin main && git push origin v{VERSION}`

**Note**: Do NOT add Co-Authored-By line. This is a release commit, not a code contribution.

### Step 6: Verify and Publish GitHub Release

After the release workflow completes:

```bash
gh run list --workflow=release.yml --limit=1
gh run view <RUN_ID>
gh release view v{VERSION}
gh release edit v{VERSION} --draft=false  # If it's a draft
```

## When to Use

Trigger this skill when user requests:
- "release", "发布", "create release", "new version", "新版本"
- "bump version", "update version", "更新版本"
- "prepare release"
- "push to remote" (with uncommitted changes)
- "publish to crates.io", "cargo publish", "推送版本"
- "trigger release action", "触发 release"

**Important**: If user says "just push" or "直接 push" with uncommitted changes, STILL follow all steps above first.
