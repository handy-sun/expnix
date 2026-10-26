---
name: rust-test-isolation
description: >-
  Isolate Rust tests that share global state — env vars, static stores,
  process-wide settings. Covers pitfalls with serial_test + tokio, env::set_var
  races, settings save/restore, and dedicated mutex patterns.
  Use when tests pass individually but fail in full suite, or when adding tests
  that touch global/static state.
tags: [rust, testing, tokio, concurrency, env-var, flaky-tests]
related_skills: [test-driven-development, systematic-debugging]
---

# Rust Test Isolation

Tests that pass individually but fail with `cargo test` (parallel) are a
recurring Rust problem. Root causes are almost always: **process-global state**
that concurrent tests mutate.

## Diagnostic: Single-threaded Confirmation

```bash
cargo test --lib -- --test-threads=1   # if this passes, it's a concurrency issue
cargo test --lib                       # if this fails, it's concurrency
cargo test --lib "specific_test"       # if this passes alone, confirms isolation issue
```

## Cause 1: `env::set_var` Races

`std::env::set_var` is **process-global and not thread-safe**. Rust 1.66+
started linting, and **Rust 1.83+ makes it `unsafe fn`** — bare calls won't
compile without an `unsafe {}` block. When 30+ tests each set `HOME`,
`CC_SWITCH_CONFIG_DIR`, etc., concurrent execution is undefined behavior.

### Temporary fix: wrap in `unsafe {}`

If you can't immediately migrate to in-memory overrides, bulk-wrap all bare
calls. Two patterns appear in test code:

```rust
// Standalone statement
unsafe { std::env::set_var("HOME", home) };

// Match arm (save/restore guard pattern)
match &self.old_home {
    Some(value) => unsafe { std::env::set_var("HOME", value) },
    None => unsafe { std::env::remove_var("HOME") },
}
```

For multi-line calls, wrap the entire block:

```rust
unsafe {
    std::env::set_var("HOME", home);
    std::env::set_var("USERPROFILE", home);
    std::env::set_var("CC_SWITCH_CONFIG_DIR", home.join(".cc-switch"));
}
```

**Bulk migration strategy** — search by two patterns, fix in batches.
See `references/bulk-unsafe-env-migration.md` for the full recipe with
all three patterns (standalone, match arms, multi-line blocks).

### Better fix: Replace with in-memory override

Instead of `env::set_var("CC_SWITCH_CONFIG_DIR", path)`, use an
`RwLock<Option<PathBuf>>` in `test_support.rs`:

```rust
// test_support.rs
fn test_home_store() -> &'static RwLock<Option<PathBuf>> {
    static STORE: OnceLock<RwLock<Option<PathBuf>>> = OnceLock::new();
    STORE.get_or_init(|| RwLock::new(None))
}

pub(crate) fn set_test_home_override(path: Option<&Path>) {
    *test_home_store().write().unwrap() = path.map(Path::to_path_buf);
}

pub(crate) fn test_home_override() -> Option<PathBuf> {
    test_home_store().read().unwrap().clone()
}
```

Production code checks the override before reading env vars:

```rust
fn get_app_config_dir() -> PathBuf {
    if let Some(override_path) = test_support::test_home_override() {
        return override_path;
    }
    // ... normal env var / default logic
}
```

### Pitfall: 35 call sites

Migrating all `env::set_var` calls is a big refactor. Do it incrementally:
fix the most-flaky tests first, leave FIXME on the rest.

## Cause 2: `serial_test::#[serial]` + `#[tokio::test]`

`serial_test` uses a `std::sync::Mutex` internally. With tokio's
**multi-threaded runtime** (the default), `#[serial]` is unreliable because:

- The mutex guard is held across `.await` points
- Tokio may move the task to a different thread between polls
- The guard can be dropped on a different thread than it was acquired on

### Fix A: `flavor = "current_thread"` (quick)

Force the test to run on a single-threaded tokio runtime:

```rust
#[tokio::test(flavor = "current_thread")]
#[serial]
async fn my_test() { ... }
```

This works but `#[serial]` still only serializes against other `#[serial]`
tests — non-`#[serial]` tests can still race.

### Fix B: Dedicated `Mutex` guard (robust)

Create a `test_support::lock_X()` function for each category of global state:

```rust
// test_support.rs
pub(crate) fn lock_codex_oauth_test() -> MutexGuard<'static, ()> {
    static LOCK: OnceLock<Mutex<()>> = OnceLock::new();
    LOCK.get_or_init(|| Mutex::new(()))
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}
```

Then in each test:

```rust
#[tokio::test(flavor = "current_thread")]
async fn my_test() {
    let _lock = lock_codex_oauth_test();  // serialize with other tests using this state
    // ... test body
}
```

### Pitfall: Guard struct must hold the lock, not just the test function

When you have an RAII guard struct (like `ConfigDirEnvGuard`, `TempHome`,
`TestHomeEnvGuard`) that sets env vars in `new()` and restores them in
`Drop`, the guard **must hold the lock as a field**. A separate local
variable at the test-function level is NOT equivalent — it can be dropped
in the wrong order, or another test can call the guard's `new()` without
acquiring the lock.

**Wrong** — lock is a separate local, guard doesn't know about it:
```rust
async fn my_test() {
    let _lock = lock_test_home_and_settings();  // separate local
    let _guard = TempHome::new();               // sets env vars, no lock
    // if _lock is reordered/dropped before _guard, env vars are unprotected
}
```

**Right** — guard owns the lock internally:
```rust
struct TempHome {
    _settings_lock: MutexGuard<'static, (), >,  // held for entire guard lifetime
    dir: TempDir,
    original_home: Option<String>,
}

impl TempHome {
    fn new() -> Self {
        let settings_lock = lock_test_home_and_settings();  // acquire inside constructor
        // ... set env vars ...
        Self { _settings_lock: settings_lock, dir, original_home }
    }
}
// Drop runs first, then _settings_lock is dropped → env vars always protected
```

This also means the test function doesn't need a separate `let _lock = ...`
line — the guard handles serialization end-to-end.

### Pitfall: `#[serial]` only serializes against other `#[serial]` tests

Even with `flavor = "current_thread"` + `#[serial]`, non-`#[serial]` tests
that mutate the same env vars will still race. If there are 35+ tests
modifying `CC_SWITCH_CONFIG_DIR` and only 3 use `#[serial]`, those 3 are
still unprotected against the other 32. This is why dedicated mutexes
+ guard-struct ownership is the robust solution.

### When to use which

| Situation | Approach |
|-----------|----------|
| Quick fix for a few tests | `flavor = "current_thread"` + `#[serial]` |
| Many tests sharing one global store | Dedicated `lock_X()` mutex |
| Tests touching env vars | Migrate to `set_test_home_override` |

## Cause 3: Settings/Config State Leaking Between Tests

Tests that modify settings (via `update_settings`, `set_current_provider`, etc.)
must **save and restore** the original values. A mutex only serializes — it
doesn't undo mutations.

### Wrong: just set to None at cleanup

```rust
#[test]
fn my_test() {
    set_test_home_override(Some(Path::new("/tmp/test")));
    // ... test
    set_test_home_override(None);  // ← clears state for concurrent tests too!
}
```

### Right: save old value, restore it

```rust
fn with_test_home<T>(test_fn: impl FnOnce() -> T) -> T {
    let _guard = lock_test_home_and_settings();
    let tmp = tempfile::tempdir().unwrap();
    let old = test_home_override();  // save
    set_test_home_override(Some(tmp.path()));
    let result = test_fn();
    set_test_home_override(old.as_deref());  // restore
    result
}
```

Same pattern for settings:

```rust
let original_settings = get_settings();
let mut settings = original_settings.clone();
settings.some_field = Some("test_value".to_string());
update_settings(&settings).unwrap();
// ... test ...
update_settings(&original_settings).unwrap();  // restore
```

## Cause 4: Global `OnceLock`/`Lazy` Stores with Reset-for-Tests

Services backed by `OnceLock<RwLock<Option<...>>>` (like `manager_store()` in
`codex_oauth.rs`) need their own mutex if tests call `reset_for_tests()`.

Pattern:

```rust
// In the service (cfg(test) only):
#[cfg(test)]
pub(crate) fn reset_for_tests() {
    let mut guard = manager_store().write().unwrap();
    *guard = None;
}

// In test_support.rs:
pub(crate) fn lock_service_test() -> MutexGuard<'static, ()> {
    static LOCK: OnceLock<Mutex<()>> = OnceLock::new();
    LOCK.get_or_init(|| Mutex::new(()))
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}
```

**Key rule**: every test that calls `reset_for_tests()` OR `seed_*` MUST
acquire `lock_service_test()` first.

## Platform-Specific Test Code

Tests using Unix-only APIs (symlinks, etc.) must be gated:

```rust
#[test]
#[cfg(unix)]
fn test_that_uses_symlink() {
    std::os::unix::fs::symlink(src, dst).unwrap();
}
```

Without `#[cfg(unix)]`, `cargo test` on Windows fails with
`use of undeclared crate or module std::os::unix`.

## Integration Tests and `#[cfg(test)]` Visibility

Rust integration tests (`tests/*.rs`) compile the library **without**
`cfg(test)` — they link against the normal library build. This means any
`#[cfg(test)] pub(crate)` functions (like `set_test_home_override()`,
`reset_for_tests()`) are **not compiled** into the library when integration
tests run.

### Symptoms

- Integration test calls `ensure_test_home()` which sets `HOME` env var
- Library code has `#[cfg(test)] fn home_dir() { test_home_override().or(dirs::home_dir()) }`
- Integration test binary doesn't see `test_home_override()` → library
  falls back to `dirs::home_dir()` → reads real `HOME`, not the override
- Tests that create files under test home but library reads real home →
  "file not found" or "assertion failed: contains_key(...)"

### Fixes (in order of preference)

1. **Expose test utilities publicly**: change `pub(crate)` to `pub` with
   `#[doc(hidden)]` for test-support functions. Integration tests can then
   call them.

2. **Create a `test-support` feature flag**: gate test utilities behind a
   Cargo feature so they're available to integration tests but not normal
   consumers:
   ```toml
   [features]
   test-support = []
   ```
   ```rust
   #[cfg(feature = "test-support")]
   pub fn set_test_home_override(path: Option<&Path>) { ... }
   ```
   Integration tests enable it: `cargo test --features test-support`

3. **Use only env vars in integration tests**: if the library reads `HOME`
   via `dirs::home_dir()`, integration tests can just set `HOME` env var
   (which `dirs` respects on Unix). This works if the library's fallback
   path reads env vars, not if it caches or uses a static.

4. **Accept the limitation**: mark integration tests that need test-home
   isolation as `#[ignore]` with a FIXME explaining why.

## Cause 5: Asserting Against the Wrong Storage Backend

Integration tests often create an `AppState` with multiple storage layers
(in-memory config, database, file system). A function may write to one
backend while the test asserts against another.

### Example: import writes to DB, test checks in-memory config

```rust
// The import function writes to state.db:
pub fn import_providers_from_live(state: &AppState) -> Result<usize, AppError> {
    let providers = read_from_file()?;
    for (id, config) in providers {
        state.db.save_provider("openclaw", &provider)?;  // ← writes to DB
    }
    Ok(imported)
}

// WRONG — checks in-memory config (never updated by import):
let guard = state.config.read().unwrap();
let manager = guard.get_manager(&AppType::OpenClaw).unwrap();
assert!(manager.providers.contains_key("openai"));  // ← always fails

// RIGHT — checks the database:
let provider = state.db.get_provider_by_id("openai", "openclaw").unwrap();
assert!(provider.is_some());  // ← correctly reflects import
```

### How to spot this

When an integration test fails with `assertion failed: contains_key(...)` or
similar, but the function returns `Ok(...)` (no error), the data was stored
somewhere the test isn't looking. Trace the write path:

1. Find the function under test
2. Identify which storage it writes to (DB, config RwLock, file, etc.)
3. Check if the test asserts against that same storage

Unit tests in the same module usually get this right because they have
direct access to the internals. Integration tests often check the wrong
thing because they use the public API surface and guess at the storage.

### Debug prints in integration tests

`#[cfg(test)]` guards on debug prints don't work in integration tests
(same `cfg(test)` visibility issue). Use env-var gating instead:

```rust
// WRONG — invisible in integration tests:
#[cfg(test)]
eprintln!("[DEBUG] path={:?}", path);

// RIGHT — works everywhere:
if std::env::var("MY_CRATE_DEBUG").ok().as_deref() == Some("1") {
    eprintln!("[DEBUG] path={:?}", path);
}
```

Run with: `MY_CRATE_DEBUG=1 cargo test --test my_integration_test -- --nocapture`

## Checklist for New Tests Touching Global State

- [ ] Does it set env vars? → use `set_test_home_override` instead
- [ ] Does it call `reset_for_tests()` / `seed_*`? → acquire dedicated mutex
- [ ] Does it modify settings? → save and restore
- [ ] Is it async with `#[tokio::test]`? → use `flavor = "current_thread"` if holding mutexes
- [ ] Does it use Unix-only APIs? → add `#[cfg(unix)]`
- [ ] Does it assert JSON key order? → check if `preserve_order` feature is on; without it, `serde_json::Map` is `BTreeMap` (alphabetical)
