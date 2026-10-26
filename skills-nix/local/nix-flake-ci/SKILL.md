---
name: nix-flake-ci
description: "Optimize CI and binary cache for NixOS/nix-darwin/home-manager flakes. Use when configuring Garnix, GitHub Actions nix builds, flake.lock update schedules, or conditional build logic based on file changes."
tags: [nix, ci, garnix, github-actions, binary-cache, flakes]
---

# Nix Flake CI Optimization

Optimize CI pipelines and binary cache usage for multi-platform Nix flakes (NixOS + nix-darwin + home-manager).

## When to Use

- Configuring Garnix for a Nix flake repository
- Setting up GitHub Actions for nix builds (dry-run or real)
- Reducing CI cost (Garnix minutes, GitHub Actions compute)
- Implementing conditional builds based on file content changes
- Scheduling flake dependency updates

## Garnix Configuration

Garnix reads `garnix.yaml` at repo root. Zero-config Nix CI + binary cache.

### Schema

```yaml
builds:
  include: []    # glob patterns for outputs to build
  exclude: []    # glob patterns to skip
  branch: main   # restrict to specific branch
```

### Branch Filtering

Default: builds on ALL branches (expensive!). Set `branch: main` to restrict:

```yaml
builds:
  include:
    - nixosConfigurations.*
    - homeConfigurations.*
    - "*.x86_64-linux.*"
    - "*.aarch64-linux.*"
  branch: main
```

### Cost Control (1500 min/month free tier)

Key cost drivers:
- Every push to every branch triggers builds
- Darwin (macOS) runners cost significantly more
- aarch64-linux uses dedicated ARM runners

Strategies:
1. Set `branch: main` — let GitHub Actions cover feature branches with dry-run
2. Remove darwin targets if GitHub Actions handles macOS builds
3. Use `magic-nix-cache-action` for binary cache on non-main branches
4. Combine with conditional build logic (see below)

## GitHub Actions: Nix Flake CI

### Two-Stage Pipeline (recommended)

```yaml
# ci.yml — runs on every push/PR
jobs:
  flake-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@v14
      - uses: DeterminateSystems/magic-nix-cache-action@v8
        with:
          use-flakehub: false
      - run: nix flake check
      - run: nix shell nixpkgs#statix -c statix check .

  build:
    needs: flake-check
    strategy:
      fail-fast: false
      matrix:
        include:
          - name: nixos-aarch64
            os: ubuntu-24.04-arm
            attr: nixosConfigurations.HOST.config.system.build.toplevel
          - name: darwin-aarch64
            os: macos-14
            attr: darwinConfigurations.HOST.config.system.build.toplevel
          - name: home-x86_64
            os: ubuntu-latest
            attr: homeConfigurations.USER.activationPackage
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@v14
      - uses: DeterminateSystems/magic-nix-cache-action@v8
        with:
          use-flakehub: false
      - run: nix build .#${{ matrix.attr }} --dry-run --quiet
```

- `nix flake check` evaluates ALL outputs on any runner — catches eval errors
- `nix build --dry-run` validates derivations resolve without building
- `ubuntu-24.04-arm` is free for public repos
- `macos-14` is Apple Silicon (aarch64-darwin)

## Conditional Builds: File Content Detection

When running scheduled cache builds, avoid redundant builds when nothing changed.

**Pitfall:** Do NOT use commit message/author heuristics (e.g. checking for `chore(deps):` prefix). Users consider this unreliable — actual file content comparison is the correct approach.

### Pattern: flake.lock Hash with GitHub Actions Cache

Three-job pipeline: check → build → save.

```yaml
# build-cache.yml
name: Build cache
on:
  schedule:
    - cron: "0 3,15 * * *"
  workflow_dispatch:

jobs:
  check-changes:
    runs-on: ubuntu-latest
    outputs:
      should_build: ${{ steps.compare.outputs.changed }}
    steps:
      - uses: actions/checkout@v4
      - run: sha256sum flake.lock > /tmp/flake-lock-hash
      - id: cache
        uses: actions/cache/restore@v4
        with:
          path: /tmp/last-hash
          key: build-cache-flake-lock
      - id: compare
        run: |
          if [ -f /tmp/last-hash ] && diff -q /tmp/flake-lock-hash /tmp/last-hash > /dev/null 2>&1; then
            echo "changed=false" >> "$GITHUB_OUTPUT"
          else
            echo "changed=true" >> "$GITHUB_OUTPUT"
          fi

  build:
    needs: check-changes
    if: needs.check-changes.outputs.should_build == 'true'
    # ... matrix builds ...

  save-hash:
    needs: [check-changes, build]
    if: needs.check-changes.outputs.should_build == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sha256sum flake.lock > /tmp/flake-lock-hash
      - uses: actions/cache/save@v4
        with:
          path: /tmp/flake-lock-hash
          key: build-cache-flake-lock
```

**Critical:** Save hash AFTER successful build, not before. If saved in `check-changes` and build fails, next run sees "no change" and skips — masking the failure.

## Dependency Update Scheduling

For flakes tracking nixpkgs-unstable (frequent updates), schedule updates to match your CI budget:

- **Daily (aggressive):** `cron: "0 0 * * *"` — high CI/Garnix consumption
- **Weekly (recommended):** `cron: "0 3 * * 6"` — Saturday 3am UTC, balances freshness vs cost
- **Bi-weekly:** `cron: "0 3 1,15 * *"` — minimal cost

Update frequency cascades: each `nix flake update` push triggers ci.yml + Garnix builds. Doubling update frequency roughly doubles CI consumption.

## Pitfalls

### magic-nix-cache-action defaults to FlakeHub auth

`magic-nix-cache-action@v8` sets `use-flakehub: true` by default. If the repo is NOT registered on FlakeHub.com, every run logs:
```
ERROR magic_nix_cache: FlakeHub: cache initialized failed: Unauthenticated: Cannot find netrc credentials for https://api.flakehub.com/
```
This is non-fatal (GHA cache still works) but noisy and confusing. Always set `use-flakehub: false` unless you've registered:

```yaml
- uses: DeterminateSystems/magic-nix-cache-action@v8
  with:
    use-flakehub: false
```

### GHA Cache service outages cause cascading failures

When GitHub Actions Cache is down (`"Our services aren't available right now"`), `magic-nix-cache-action` can't restore or save caches. Combined with no Garnix cache on non-main branches, this means builds compile from scratch → timeout (6h) or OOM → runner loses communication. This is transient — rerun after GitHub recovers. Not a config problem.

### Beszel test flakiness on CI runners

The `beszel` package has timing-sensitive tests (e.g. `TestServiceUpdateCPUPercent` asserts CPU% ≤ 100, but multi-core CI runners can report >100%). When new flaky tests appear in CI but pass locally, add them to `skippedTests` in `overlays/beszel.nix`. See [beszel-overlay-maintenance.md](references/beszel-overlay-maintenance.md) for the pattern.

## Cost Estimation

| Config | Garnix min/ci (approx) |
|--------|----------------------|
| 4 configs, daily updates | ~400 min/day → 12,000/month |
| 4 configs, weekly updates | ~400 min/week → 1,700/month |
| 2 configs (no darwin), weekly | ~200 min/week → 850/month |
