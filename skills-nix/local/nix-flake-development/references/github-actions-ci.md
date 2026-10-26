# GitHub Actions CI for Multi-System Nix Flakes

Two-stage pattern: eval gate → native build matrix.

## Stage 1: flake-check

Runs on `ubuntu-latest` (cheapest). `nix flake check` evaluates ALL outputs across ALL systems — catches eval errors, option typos, and nixfmt violations in one shot, regardless of the runner's architecture.

```yaml
flake-check:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: DeterminateSystems/nix-installer-action@v14
    - uses: DeterminateSystems/magic-nix-cache-action@v8
    - run: nix flake check
    - run: nix shell nixpkgs#statix -c sh -c 'statix check . 2>&1 | tee /dev/stderr | grep -q "^\[E" && exit 1 || exit 0'
```

## Stage 2: build matrix

`nix build --dry-run` validates derivation evaluation + input resolution without building. Runs on native platform runners.

```yaml
build:
  needs: flake-check
  strategy:
    fail-fast: false
    matrix:
      include:
        - name: expnix (aarch64-linux)
          os: ubuntu-24.04-arm          # Arm partner runner
          attr: nixosConfigurations.expnix.config.system.build.toplevel
        - name: nixwsl (x86_64-linux)
          os: ubuntu-latest
          attr: nixosConfigurations.nixwsl.config.system.build.toplevel
        - name: buking (x86_64-linux)
          os: ubuntu-latest
          attr: nixosConfigurations.buking.config.system.build.toplevel
        - name: handyMini (aarch64-darwin)
          os: macos-14                   # Apple Silicon
          attr: darwinConfigurations.handyMini.config.system.build.toplevel
        - name: home (x86_64-linux)
          os: ubuntu-latest
          attr: homeConfigurations.qi.activationPackage
  name: build ${{ matrix.name }}
  runs-on: ${{ matrix.os }}
  steps:
    - uses: actions/checkout@v4
    - uses: DeterminateSystems/nix-installer-action@v14
    - uses: DeterminateSystems/magic-nix-cache-action@v8
    - run: nix build .#${{ matrix.attr }} --dry-run
```

## Trigger patterns

```yaml
# Recommended: main + dev branches, skip docs/config changes
on:
  push:
    branches: [main, "dev*"]
    paths-ignore:
      - "**.md"
      - "Justfile"
      - ".gitignore"
      - "LICENSE"
  pull_request:
    branches: [main, "dev*"]
    paths-ignore:
      - "**.md"
      - "Justfile"
      - ".gitignore"
      - "LICENSE"
```

**paths-ignore pitfall**: GitHub Actions runs on Linux runners where paths are **case-sensitive**. The file is `Justfile` (capital J), not `justfile`. A lowercase `justfile` in paths-ignore won't match and the CI will still trigger on Justfile changes. Always verify the exact filename with `git ls-files | grep -i justfile`.

## Runner Reference

| Runner label          | Arch    | OS      | Free for public repos |
|-----------------------|---------|---------|----------------------|
| ubuntu-latest         | x86_64  | Linux   | Yes                  |
| ubuntu-24.04-arm      | aarch64 | Linux   | Yes (partner runner) |
| macos-14              | aarch64 | macOS   | Yes (10x min rate)   |
| macos-latest          | aarch64 | macOS   | Yes (10x min rate)   |

- `ubuntu-24.04-arm` is provided by Arm Limited, GA status. YAML label: `ubuntu-24.04-arm`.
- macOS runners cost 10x minutes multiplier. For private repos, budget accordingly.
- No free x86_64-darwin runner exists (macos-14-large requires paid larger runners).

## Key Behaviors

- `nix flake check` evaluates `nixosConfigurations`, `darwinConfigurations`, `homeConfigurations`, `formatter`, `checks` across ALL declared systems — even on x86_64 runner, aarch64-linux/darwin configs are evaluated.
- `nix build --dry-run` only works for the runner's native architecture. Cross-arch dry-run fails because Nix refuses to build for a different `system` field.
- `statix check .` catches unused bindings, legacy patterns, simplifiable expressions. Separate from `nix flake check`.
- `magic-nix-cache-action` caches Nix store paths between runs. Significant speedup on repeated PRs.

## Cache Population via Schedule Trigger

`magic-nix-cache-action` only caches paths that are actually built. If CI only runs `--dry-run`, the cache stays empty. To populate the cache:

1. Add `schedule` trigger to ci.yml (offset from update-deps by 2-3 hours)
2. Remove `--dry-run` from the build step — schedule runs do real builds, push/PR runs benefit from cache

```yaml
on:
  schedule:
    - cron: "0 3,15 * * *"    # 03:00 and 15:00 UTC
  workflow_dispatch:            # manual trigger
```

Cron offset strategy: if update-deps runs at 00/12 UTC, CI runs at 03/15 UTC. The 3-hour buffer ensures CI builds the updated lock.

**Disable FlakeHub and telemetry** (optional):
```yaml
- uses: DeterminateSystems/magic-nix-cache-action@v8
  with:
    use-flakehub: "disabled"
    diagnostic-endpoint: ""
```

## Scheduled Dependency Updates

Separate workflow (`update-deps.yml`) that auto-updates `flake.lock` on schedule and pushes directly to main.

```yaml
name: Update dependencies
on:
  schedule:
    - cron: "0 0,12 * * *"     # 00:00 and 12:00 UTC
  workflow_dispatch:

permissions:
  contents: write

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@v14
      - run: nix flake update
      - run: |
          if git diff --quiet flake.lock; then
            echo "No changes to flake.lock"
            exit 0
          fi
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add flake.lock
          git commit --no-verify -m "chore(deps): update flake.lock"
          git push
```

Key points:
- `--no-verify` skips pre-commit hooks (nixfmt, etc.) — the commit only touches flake.lock
- `git diff --quiet flake.lock` prevents empty commits when nothing changed
- Using default `GITHUB_TOKEN` — the push does NOT trigger CI (GitHub policy). CI will run on the next scheduled run or manual dispatch. If you need CI to trigger on the auto-commit, use a PAT stored as a secret.
- Cron at 00/12 UTC, CI at 03/15 UTC — 3h buffer ensures CI builds the fresh lock.

Alternative: use `DeterminateSystems/update-flake-lock@main` action which creates a PR instead of direct push. Requires PAT for CI to trigger on the PR. More conservative (human reviews before merge).

## Pitfalls

### statix exits 1 on warnings

`statix check .` returns exit code 1 when it finds ANY warning (W20 repeated keys, W08 useless parens, W10 empty pattern). This fails the entire flake-check job and blocks all downstream build jobs (via `needs:`).

Options:
1. Run `statix fix .` locally first to auto-fix most warnings (W20, W08, W10 are all auto-fixable)
2. Use `statix check . --quiet` to suppress output but still fail (doesn't help)
3. Wrap: `statix check . || true` — swallows failures (defeats the purpose)
4. **Error-only filtering** — fail only on errors (E-level), allow warnings:
   ```yaml
   - run: nix shell nixpkgs#statix -c sh -c 'statix check . 2>&1 | tee /dev/stderr | grep -q "^\[E" && exit 1 || exit 0'
   ```
   This lets warnings (W20 repeated keys in NixOS module patterns, etc.) pass while catching real errors. Useful when you can't fix all warnings immediately (e.g., W20 from NixOS module system's repeated `enable`/`package` keys is a false positive).
5. Best: fix warnings locally before pushing. statix warnings are real code smells (repeated keys, useless parens) worth fixing.

### nix build --dry-run is arch-locked

`nix build .#nixosConfigurations.expnix.config.system.build.toplevel --dry-run` on x86_64 runner fails because the derivation's `system` field is `aarch64-linux`. Nix refuses to evaluate cross-arch builds even with `--dry-run`. Must use a matching runner.

## Garnix (Alternative CI)

Garnix is a Nix-specific CI + binary cache service. Install the GitHub App, push a `garnix.yaml` to the repo root.

### Setup

1. Go to https://app.garnix.io, log in with GitHub
2. Install Garnix GitHub App, grant access to the target repo
3. Create `garnix.yaml` in repo root:
   ```yaml
   builds:
     include:
       - nixosConfigurations.*
       - darwinConfigurations.*
       - homeConfigurations.*
       - "*.x86_64-linux.*"
       - "*.aarch64-linux.*"
       - "*.aarch64-darwin.*"
   ```
4. Push — Garnix triggers on every push/PR

### Build status

Garnix builds appear as commit status on GitHub. The Garnix dashboard (`app.garnix.io/commit/<sha>`) shows per-derivation build status. **Builds can queue for 10-30+ minutes on free tier** — this is normal, not an error. If still pending after 30min, check:
- Is the Garnix App installed and repo activated?
- Any alerts on the Garnix dashboard?

### Pricing (Free tier)

- 1,500 minutes/month CI builds
- Public + private binary cache
- Extra: $0.006/minute

### Garnix vs GitHub Actions

| Feature              | Garnix                      | GitHub Actions               |
|----------------------|-----------------------------|------------------------------|
| Setup                | Zero-config (GitHub App)    | Write workflow YAML          |
| Binary cache         | Built-in                    | Separate (Cachix, etc.)      |
| Custom steps         | No (Nix-only)               | Yes (lint, statix, etc.)     |
| aarch64-linux        | Supported                   | ubuntu-24.04-arm (free)      |
| Free tier            | 1500 min/month              | Unlimited for public repos   |
| Incremental builds   | Yes (automatic)             | Via magic-nix-cache-action   |
| Queue time           | 10-30+ min on free tier     | Usually < 1 min              |

Recommendation: Use GitHub Actions for full control (lint, statix, custom steps). Use Garnix for zero-config + built-in binary cache. Can be used together — Garnix provides the cache, GitHub Actions provides the checks.
