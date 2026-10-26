# Artifact Recovery from Failed Release Uploads

## Problem

GitHub Actions release workflow with matrix strategy (parallel jobs) using `softprops/action-gh-release` can lose assets due to race conditions. Each parallel job creates/updates the release independently.

## Step-by-Step Recovery

### 1. Identify Missing Assets

```bash
# What's in the release
gh release view v0.2.1 --json assets --jq '.assets[].name'

# What was built (all artifacts from the workflow run)
gh api repos/OWNER/REPO/actions/runs/RUN_ID/artifacts --jq '.artifacts[].name'
```

Compare the two lists to find missing assets.

### 2. Download Missing Artifacts

GitHub Actions artifacts API returns **ZIP files**, not the raw archives:

```bash
# Get artifact ID
gh api repos/OWNER/REPO/actions/runs/RUN_ID/artifacts --jq '.artifacts[] | select(.name | test("PATTERN")) | "\(.id) \(.name)"'

# Download (returns ZIP)
gh api "repos/OWNER/REPO/actions/artifacts/ARTIFACT_ID/zip" > artifact.zip

# Extract — inner file is the actual release archive
unzip artifact.zip -d tmp/
ls tmp/  # e.g., rcheat-v0.2.1-aarch64-apple-darwin.tar.gz
```

### 3. Upload to Release

```bash
gh release upload v0.2.1 tmp/rcheat-v0.2.1-aarch64-apple-darwin.tar.gz
```

Must be run from within the git repository (gh needs git context).

### 4. Verify

```bash
gh release view v0.2.1
```

All expected assets should now be listed.

## Real Example (rcheat v0.2.1)

- 8 build targets, only 5 assets uploaded
- Missing: aarch64-apple-darwin, aarch64-unknown-linux-musl, x86_64-apple-darwin
- Downloaded from workflow artifacts, unzipped, uploaded to draft release
- Result: complete 8/8 assets in draft release
