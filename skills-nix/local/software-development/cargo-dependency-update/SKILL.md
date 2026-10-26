---
name: cargo-dependency-update
description: Update Rust crate dependencies in Cargo.toml. Categorize by risk, check changelogs for breaking changes, verify against actual API usage, apply safe bumps first. Use when the user says update dependencies, upgrade crates, bump versions, or cargo update.
---

# Cargo Dependency Update

Update Rust dependencies safely. Not all version bumps are equal — 0.x crates have different semver rules, and changelog breaking changes may not affect your actual API surface.

## Workflow

### 1. Inventory current vs latest

For each dependency in Cargo.toml, query crates.io:

```sh
curl -s 'https://crates.io/api/v1/crates/<name>' | jq -r '.crate.max_stable_version'
```

### 2. Categorize by risk

| Pattern | Risk | Action |
|---------|------|--------|
| `^1.x` → latest `1.y` | None | Bump lower bound if desired |
| `^0.x` → latest `0.x` (same minor) | None | Bump |
| `^0.x` → latest `0.y` (different minor) | **HIGH** | Check changelog before bumping |
| Exact pin `1.2.3` → `1.4.0` | Low | Consider changing to caret range |
| Any → major version jump | **HIGH** | Full migration review needed |

Key rule: **In 0.x semver, a minor bump (0.2 → 0.3) is a breaking change.** Treat `^0.9` → `0.10` the same as `^1` → `^2`.

### 3. Check breaking changes — but only for YOUR API surface

Don't just read changelogs blindly. **Check whether the breaking changes affect APIs your code actually uses.**

Approach:
1. Read the CHANGELOG / release notes for the breaking version
2. For each listed breaking change, grep your source to see if you use the affected API
3. If the breaking change is in an API you never call, it's safe to bump

Example from this session: goblin 0.10 had breaking changes, but ALL were in PE parsing. Project only uses ELF parsing → safe to bump.

### 4. Complex crates — extra caution

These crates tend to have significant API surface changes between 0.x versions:
- **gimli** — DWARF parsing (FallibleIterator removal, Result return changes, lifetime rework)
- **object** — binary object reading (d_tag type changes, relocation encoding)
- **mlua** — Lua bindings (Lua version upgrades, async changes)
- **tabled** — table formatting (renamed methods, changed semantics)
- **nix** — Unix system calls (I/O safety adoption, feature-gated APIs)

For these: read the actual CHANGELOG, not just the version number. Use `delegate_task` to parallelize changelog checks.

### 5. Apply and verify

```sh
# Edit Cargo.toml
cargo check           # compilation pass
cargo clippy          # lint pass
cargo test            # if tests exist
```

Fix any code-level breaking changes (renamed methods, changed signatures) before moving on.

### 6. Version constraint style

- **Respect the existing style** in Cargo.toml — if the project uses `^1.0`, don't change to `">=1.0, <2.0"`
- Prefer caret ranges over exact pins for library deps (e.g. `^1.21` not `1.21.4`)
- Exact pins (`1.19.0`) are unusual — when updating, convert to caret unless there's a specific reason

## Pitfalls

- **Duplicate entries**: When patching Cargo.toml, watch for duplicate lines if the patch tool appends rather than replaces. Always verify with a grep after patching.
- **New Rust lints after dependency bump**: Updating deps may expose new compiler warnings (e.g. `mismatched_lifetime_syntaxes` in Rust 1.95). Fix these in the same pass.
- **Subagent timeouts**: Changelog lookups for large projects (e.g. nix with 100K+ char CHANGELOG) can timeout. Use targeted curl + grep instead of full file reads.
- **Don't update gimli/object casually**: These crates have MASSIVE breaking changes between 0.x versions. Treat them as major migrations, not routine bumps.
