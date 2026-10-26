---
name: desktop-app-qt6-ci
description: "CI/CD for Qt6 desktop applications. Companion to desktop-app-ci (Qt5). Covers Qt6 package naming on each platform, runner selection, and workflow filename pitfalls."
tags: [ci, github-actions, qt6, cpp, desktop, cross-platform]
---

# Desktop App Qt6 CI (GitHub Actions)

Companion to `desktop-app-ci` (which covers Qt5). This skill covers Qt6-specific differences for cross-platform CI.

## When to Use

- Setting up CI for a Qt6 desktop application
- Migrating an existing Qt5 CI to Qt6
- Debugging Qt6 package installation on CI runners

## Qt6 Package Installation by Platform

### Ubuntu (apt)

Qt6 packages use different naming than Qt5 (`qtbase5-dev` → `qt6-base-dev`):

```yaml
- name: Install Qt (apt)
  if: matrix.qt_from_apt
  run: >-
    sudo apt-get update && sudo apt-get install -y
    qt6-base-dev
    qt6-tools-dev
    qt6-l10n-tools
    qt6-multimedia-dev
    libqt6svg6-dev
```

**Use Ubuntu 24.04** (`ubuntu-24.04` / `ubuntu-24.04-arm`) — Qt6 apt packages are more complete than 22.04.

### macOS (Homebrew)

Qt6 is now the default `qt` formula. No need for `qt@6`:

```yaml
- name: Install Qt (brew)
  if: matrix.qt_from_brew
  run: |
    brew install qt
    echo "QT_ROOT_DIR=$(brew --prefix qt)" >> "$GITHUB_ENV"
    echo "$(brew --prefix qt)/bin" >> "$GITHUB_PATH"
```

**Pitfall:** Don't use `qt@5` — that's the legacy Qt5 formula. `qt` = Qt6.

### Windows (install-qt-action)

```yaml
- uses: jurplel/install-qt-action@v4
  with:
    version: '6.7.2'
    target: desktop
    cache: true
```

**Pitfall:** Qt 6.0+ dropped official Windows x86 prebuilt binaries. The `install-qt-action` may fail for `win32_msvc2019` with Qt6. Consider dropping x86 or using cross-compilation.

## Runner Selection (Qt6-specific)

- **Linux**: Use `ubuntu-24.04` (not 22.04) for complete Qt6 apt packages.
- **Linux ARM64**: `ubuntu-24.04-arm` works with Qt6 apt packages.
- **macOS Intel**: `macos-26-intel` is the correct runner name (NOT `macos-13` which is outdated).
- **macOS Apple Silicon**: Default macOS runners work; `brew install qt` provides arm64 Qt6.
- **Windows**: `windows-2022` with MSVC 2022.

## Workflow Filename Pitfall

**Do NOT name Qt6 CI files `build-*.yml`** if the project has a `.gitignore` pattern like `*build-*` (common for CMake build directories). The glob matches workflow filenames too.

Safe naming:
- `ci-qt6.yml` ✅
- `build-qt6.yml` ❌ (matches `*build-*` gitignore pattern)

Verify with: `git check-ignore -v .github/workflows/<filename>`

## Qt5 vs Qt6 — Quick Diff

| Aspect | Qt5 CI | Qt6 CI |
|--------|--------|--------|
| apt packages | `qtbase5-dev qttools5-dev qtmultimedia5-dev` | `qt6-base-dev qt6-tools-dev qt6-l10n-tools qt6-multimedia-dev libqt6svg6-dev` |
| brew formula | `qt@5` | `qt` |
| Ubuntu version | 22.04 OK | 24.04 recommended |
| Windows x86 | Supported (5.15.2) | No official prebuilt |
| WinXP target | Possible (Qt 5.6 + v141_xp) | Not supported |

## Pitfalls Summary

1. **Qt6 apt package names differ from Qt5** — `qt6-base-dev` not `qtbase6-dev`
2. **`brew install qt` = Qt6** — don't use `qt@6` (doesn't exist), don't use `qt@5` (legacy)
3. **Qt6 no Windows x86 prebuilt** — `install-qt-action` may fail for 32-bit
4. **Workflow filename gitignore collision** — `*build-*` pattern matches `build-qt6.yml`; use `ci-qt6.yml`
5. **Ubuntu 24.04 for Qt6 apt** — 22.04 has incomplete Qt6 packages
6. **`macos-26-intel` is valid** — correct runner for Intel macOS 26 builds
