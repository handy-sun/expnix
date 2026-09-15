#!/usr/bin/env bash
#
# Refresh the version + hash pinned inline in this repo's package definitions.
# Flake inputs are handled by `just upc-nix` / `just upc-my`; these packages have
# no lock file, so their versions and SRI hashes live in the .nix files instead.

set -euo pipefail

usage() {
  cat << 'EOF'
Usage:
  update-pkgs.sh [options] [PACKAGE ...]

Packages:
  helium                 packages/helium.nix
  zcode                  packages/zcode.nix
  honk-core              modules/honk/package.nix
  bibata-rainbow-modern  packages/bibata-rainbow-modern.nix

  With no PACKAGE given, all of them are checked.

Options:
  -n, --dry-run     Report available updates without touching any file
      --no-commit   Rewrite the files but do not create a commit
  -b, --build       Build each updated package before committing; on failure
                    nothing is committed
  -h, --help        Show this help

Examples:
  update-pkgs.sh --dry-run
  update-pkgs.sh --no-commit honk-core
  update-pkgs.sh --build
EOF
}

ALL_PKGS=(helium zcode honk-core bibata-rainbow-modern)

# fetchzip hashes the unpacked, root-stripped tree, so it cannot be prefetched
# from the URL. Substitute this, let the build fail, and read the real hash back
# out of the "got:" line.
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

die() {
  printf 'update-pkgs: %s\n' "$*" >&2
  exit 1
}

info() { printf '%s\n' "$*" >&2; }

# ---------------------------------------------------------------- package table

pkg_file() {
  case $1 in
    helium) echo packages/helium.nix ;;
    zcode) echo packages/zcode.nix ;;
    honk-core) echo modules/honk/package.nix ;;
    bibata-rainbow-modern) echo packages/bibata-rainbow-modern.nix ;;
    *) die "unknown package: $1" ;;
  esac
}

# fetchurl pins a flat file hash, fetchzip pins an unpacked tree hash.
pkg_hash_mode() {
  case $1 in
    bibata-rainbow-modern) echo fetchzip ;;
    *) echo flat ;;
  esac
}

pkg_latest_version() {
  case $1 in
    helium) gh_latest_tag imputnet/helium-linux ;;
    bibata-rainbow-modern) gh_latest_tag ful1e5/Bibata_Cursor_Rainbow ;;
    # Every honk release is flagged as a prerelease, so /releases/latest 404s.
    honk-core) gh_newest_tag daeuniverse/honk ;;
    zcode) zcode_latest_version ;;
  esac
}

# Emits "SLOT<TAB>URL" per artifact. SLOT is "single" when the file holds one
# hash, otherwise the nix system the hash belongs to.
pkg_assets() {
  local v=$2
  case $1 in
    helium)
      printf 'single\thttps://github.com/imputnet/helium-linux/releases/download/%s/helium-%s-x86_64.AppImage\n' "$v" "$v"
      ;;
    zcode)
      printf 'single\thttps://cdn-zcode.z.ai/zcode/electron/releases/%s/linux-x64/ZCode-%s-linux-x64.AppImage\n' "$v" "$v"
      ;;
    honk-core)
      printf 'x86_64-linux\thttps://github.com/daeuniverse/honk/releases/download/v%s/honk-core-v%s-x86_64-unknown-linux-musl.tar.gz\n' "$v" "$v"
      printf 'aarch64-linux\thttps://github.com/daeuniverse/honk/releases/download/v%s/honk-core-v%s-aarch64-unknown-linux-musl.tar.gz\n' "$v" "$v"
      ;;
    bibata-rainbow-modern)
      printf 'single\thttps://github.com/ful1e5/Bibata_Cursor_Rainbow/releases/download/v%s/Bibata-Rainbow-Modern.tar.gz\n' "$v"
      ;;
  esac
}

# ------------------------------------------------------------ upstream lookups

gh_json() {
  if command -v gh > /dev/null 2>&1; then
    # Authenticated, so not subject to the 60 requests/hour anonymous limit.
    gh api "$1"
  else
    curl -fsSL --max-time 30 "https://api.github.com/$1"
  fi
}

gh_latest_tag() {
  gh_json "repos/$1/releases/latest" | jq -er '.tag_name' | sed 's/^v//'
}

gh_newest_tag() {
  gh_json "repos/$1/releases?per_page=20" \
    | jq -er '[.[] | select(.draft | not)][0].tag_name' | sed 's/^v//'
}

# The CDN exposes no manifest and its bucket listing is forbidden, but the
# download page embeds the AppImage names. Older releases are listed too, so
# take the highest version rather than the first match.
zcode_latest_version() {
  curl -fsSL --max-time 30 https://zcode.z.ai/ \
    | grep -oE 'ZCode-[0-9]+(\.[0-9]+)+-linux-x64\.AppImage' \
    | sed -E 's/^ZCode-(.*)-linux-x64\.AppImage$/\1/' \
    | sort -V | tail -n1
}

# --------------------------------------------------------------- file rewriting

# BSD sed takes a mandatory argument to -i, GNU sed does not; this repo is also
# used from darwinConfigurations, so avoid -i entirely.
sed_i() {
  local script=$1 file=$2
  sed "$script" "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
}

current_version() {
  sed -n 's/^[[:space:]]*version = "\([^"]*\)";[[:space:]]*$/\1/p' "$(pkg_file "$1")" | head -n1
}

set_version() {
  sed_i "s|^\([[:space:]]*\)version = \"[^\"]*\";|\1version = \"$2\";|" "$(pkg_file "$1")"
}

set_hash() {
  local file=$1 slot=$2 hash=$3
  if [[ $slot == single ]]; then
    sed_i "s|hash = \"[^\"]*\"|hash = \"$hash\"|" "$file"
  else
    # Confine the substitution to the matching arch block so the two honk-core
    # hashes cannot end up swapped.
    sed_i "/$slot = {/,/};/ s|hash = \"[^\"]*\"|hash = \"$hash\"|" "$file"
  fi
}

# --------------------------------------------------------------------- hashing

prefetch_flat() {
  nix store prefetch-file --json --hash-type sha256 "$1" | jq -er '.hash'
}

nix_system() {
  nix eval --impure --raw --expr builtins.currentSystem
}

build_expr() {
  local file=$1
  printf '(builtins.getFlake "%s").inputs.nixpkgs.legacyPackages."%s".callPackage %s/%s { }' \
    "$REPO_ROOT" "$SYSTEM" "$REPO_ROOT" "$file"
}

build_pkg() {
  nix build --impure --no-link --print-out-paths --expr "$(build_expr "$(pkg_file "$1")")"
}

# Poison the hash, build, and scrape the real one out of the mismatch report.
hash_via_build() {
  local name=$1 file out got
  file=$(pkg_file "$name")

  set_hash "$file" single "$FAKE_HASH"
  out=$(build_pkg "$name" 2>&1) || true
  got=$(printf '%s\n' "$out" \
    | sed -n 's/.*got:[[:space:]]*\(sha256-[A-Za-z0-9+/=]*\).*/\1/p' | head -n1)

  [[ -n $got ]] || {
    printf '%s\n' "$out" >&2
    die "$name: could not read the real hash out of the build output"
  }
  printf '%s\n' "$got"
}

update_pkg() {
  local name=$1 version=$2 file slot url hash
  file=$(pkg_file "$name")

  # The version has to land first: the fetchzip path builds the derivation to
  # discover its hash, and that build must already point at the new URL.
  set_version "$name" "$version"

  case $(pkg_hash_mode "$name") in
    flat)
      while IFS=$'\t' read -r slot url; do
        info "  prefetching $url"
        hash=$(prefetch_flat "$url")
        set_hash "$file" "$slot" "$hash"
      done < <(pkg_assets "$name" "$version")
      ;;
    fetchzip)
      info "  resolving unpacked-tree hash via a throwaway build"
      hash=$(hash_via_build "$name")
      set_hash "$file" single "$hash"
      ;;
  esac
}

# ------------------------------------------------------------------------ main

dry_run=false
do_commit=true
do_build=false
selected=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -n | --dry-run) dry_run=true ;;
    --no-commit) do_commit=false ;;
    -b | --build) do_build=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "unknown option: $1 (try --help)" ;;
    *) selected+=("$1") ;;
  esac
  shift
done

[[ ${#selected[@]} -gt 0 ]] || selected=("${ALL_PKGS[@]}")

for cmd in jq curl nix git; do
  command -v "$cmd" > /dev/null 2>&1 || die "missing required command: $cmd"
done

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"
SYSTEM=$(nix_system)

changed_files=()
changelog=()

for name in "${selected[@]}"; do
  file=$(pkg_file "$name")
  cur=$(current_version "$name")
  [[ -n $cur ]] || die "$name: no version found in $file"

  latest=$(pkg_latest_version "$name") || die "$name: upstream version lookup failed"
  [[ -n $latest ]] || die "$name: upstream returned an empty version"

  if [[ $cur == "$latest" ]]; then
    printf '%-22s %s (up to date)\n' "$name" "$cur"
    continue
  fi

  printf '%-22s %s -> %s\n' "$name" "$cur" "$latest"
  $dry_run && continue

  update_pkg "$name" "$latest"
  # The pre-commit hook rejects unformatted staged .nix files.
  command -v nixfmt > /dev/null 2>&1 && nixfmt "$file"

  changed_files+=("$file")
  changelog+=("- $name: $cur -> $latest")
done

if [[ ${#changed_files[@]} -eq 0 ]]; then
  $dry_run || info "nothing to update"
  exit 0
fi

if $do_build; then
  for entry in "${changelog[@]}"; do
    name=${entry#- }
    name=${name%%:*}
    info "building $name"
    build_pkg "$name" > /dev/null || die "$name: build failed, nothing committed"
  done
fi

$do_commit || {
  info "files updated, commit skipped"
  exit 0
}

git add -- "${changed_files[@]}"
git commit -m "chore(packages): update pinned versions

$(printf '%s\n' "${changelog[@]}")"
