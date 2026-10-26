---
name: desktop-app-ci
description: "CI/CD for native desktop applications (Qt, C++, Rust/Tauri, Swift/Electron). Covers cross-platform matrix builds, Qt installation pitfalls, macOS runner selection, deploy tooling, and artifact packaging. Use when setting up or debugging GitHub Actions for desktop app builds."
tags: [ci, github-actions, qt, cpp, desktop, cross-platform, macos, windows]
---

# Desktop App CI (GitHub Actions)

Cross-platform CI for native desktop applications. Covers Qt/C++ primarily but patterns apply to any desktop framework.

## When to Use

- Setting up CI for a Qt/C++ desktop application
- Debugging `windeployqt` / `macdeployqt` failures
- Building x86 + x64 Windows binaries from a single matrix
- Choosing the right macOS runner for Intel vs Apple Silicon builds
- Packaging release artifacts (zip, dmg, AppImage, installer)

## Qt Installation — Two Approaches

### `jurplel/install-qt-action` (preferred for standard archs)

Auto-adds Qt bin to `$GITHUB_PATH` — deploy tools work out of the box.

```yaml
- uses: jurplel/install-qt-action@v4
  with:
    version: '5.15.2'
    target: desktop
    cache: true
    aqtversion: '==2.0.0'  # needed for Qt 5.6.x only
```

### `aqtinstall` (manual — for archs install-qt-action doesn't cover)

Does NOT add to PATH. Must manually export both `$GITHUB_ENV` and `$GITHUB_PATH`.

```yaml
- name: Install Qt x86 (aqt)
  shell: bash
  run: |
    pip install aqtinstall
    aqt install-qt windows desktop 5.15.2 win32_msvc2019
    echo "QT_ROOT_DIR=$(pwd)/5.15.2/msvc2019" >> "$GITHUB_ENV"
    echo "$(pwd)/5.15.2/msvc2019/bin" >> "$GITHUB_PATH"
```

**Pitfall:** `$GITHUB_ENV` sets env vars (for CMake's `-DCMAKE_PREFIX_PATH`), but only `$GITHUB_PATH` puts tools like `windeployqt` on PATH. Missing `$GITHUB_PATH` → exit code 127 (command not found).

## macOS Runner Selection

| Runner | Arch | Qt 5.15 compat | Notes |
|--------|------|----------------|-------|
| `macos-13` | x86_64 (Intel) | ✅ | **Last Intel runner** |
| `macos-14` | aarch64 (Apple Silicon) | ❌ (no prebuilt) | Default for macOS jobs |
| `macos-15` | aarch64 (Apple Silicon) | ❌ (no prebuilt) | Latest |

**Pitfall:** `macos-12` is deprecated/removed. `macos-N` where N is the macOS version number. There is no `macos-26-intel` or similar — GitHub uses version numbers, not arbitrary labels.

Qt 5.15 has no official arm64 macOS prebuild. For Apple Silicon, either build Qt from source or use Homebrew's `qt@5`.

## Windows Matrix: x64 + x86

```yaml
matrix:
  include:
    - os: windows-2022
      qt_version: 5.15.2
      arch: x64
      artifact: myapp-win-x64
    - os: windows-2022
      qt_version: 5.15.2
      arch: x86
      artifact: myapp-win-x86
```

CMake `-A` flag maps arch:
```yaml
run: cmake -S . -B build -G "Visual Studio 17 2022" \
  -A ${{ matrix.arch == 'x86' && 'Win32' || 'x64' }} \
  -DCMAKE_PREFIX_PATH="$QT_ROOT_DIR"
```

Use `ilammy/msvc-dev-cmd@v1` with `arch: ${{ matrix.arch || 'x64' }}` for MSVC env setup.

## CMake Multi-OS Configure

Split per OS to avoid quoting issues with platform-specific flags:

```yaml
- name: CMake configure (Windows)
  if: runner.os == 'Windows'
  shell: bash
  run: cmake -S . -B build -G "Visual Studio 17 2022" -A ... -DCMAKE_PREFIX_PATH="$QT_ROOT_DIR"

- name: CMake configure (Linux)
  if: runner.os == 'Linux'
  run: cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-include limits"

- name: CMake configure (macOS)
  if: runner.os == 'macOS'
  run: cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$QT_ROOT_DIR"
```

**Pitfall:** GCC 13+ on Ubuntu 22.04+ may need `-include limits` for `<limits>` header. Don't put this in a shared env var — it breaks MSVC.

## Deploy Tools

| Tool | Platform | Typical invocation |
|------|----------|--------------------|
| `windeployqt` | Windows | `windeployqt --no-translations --plugindir bin/plugins bin/app.exe` |
| `macdeployqt` | macOS | `macdeployqt bin/app.app -dmg` |
| `linuxdeploy` | Linux | AppImage creation (separate install needed) |

## Experimental / Non-blocking Builds

Use `continue-on-error` + `experimental` matrix flag for builds that shouldn't block the pipeline:

```yaml
matrix:
  include:
    - os: windows-2022
      artifact: myapp-win-xp
      experimental: true
continue-on-error: ${{ matrix.experimental || false }}
```

## Release Artifact Pattern

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: ${{ matrix.artifact }}
    path: ${{ matrix.artifact }}.*

release:
  if: startsWith(github.ref, 'refs/tags/v')
  needs: build
  steps:
    - uses: actions/download-artifact@v4
    - uses: softprops/action-gh-release@v2
      with:
        draft: true
        files: |
          artifact-1/*
          artifact-2/*
```

## Pitfalls Summary

1. **`aqtinstall` without `$GITHUB_PATH`** → `windeployqt` exit code 127
2. **`macos-26-intel` doesn't exist** → use `macos-13` for Intel
3. **Single CMake configure step for all OS** → quoting nightmares, split per OS
4. **Qt 5.15 on Apple Silicon** → no prebuild, use Homebrew or build from source
5. **GCC 13 `-include limits`** → must be Linux-only, breaks MSVC
