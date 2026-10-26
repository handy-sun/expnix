# Storage Backend Mismatch in Tests

## Case: cc-switch-cli openclaw import tests (2026-05-08)

### Symptom
Two integration tests in `import_export_sync.rs` failed:
- `import_openclaw_providers_then_export_roundtrip`
- `import_openclaw_providers_then_switch`

Both asserted `manager.providers.contains_key("openai")` against `state.config` (in-memory `MultiAppConfig`), which returned empty.

### Root Cause
`import_openclaw_providers_from_live()` writes directly to `state.db` (SQLite database via `dao::provider`), not to `state.config` (in-memory struct). The in-memory config remained at `MultiAppConfig::default()` (empty providers).

### Fix
Changed assertions to query `state.db`:
```rust
// Before (wrong — checks in-memory config, never updated by import)
let cfg = state.config.read();
let manager = cfg.get_manager(&AppType::OpenClaw);
assert!(manager.providers.contains_key("openai"));

// After (correct — checks the actual storage backend)
assert!(state.db.get_provider_by_id("openai").is_some());
assert!(state.db.get_provider_ids().contains(&"openai".to_string()));
```

### Pattern Recognition
When you see:
1. A function that takes `db` / `store` / `persistence` as a parameter
2. A test that asserts against a different data structure (config, state, cache)
3. The test fails because "the value isn't there"

→ Check if the function writes to the db, not the in-memory struct.

### Related Code Patterns
- Unit test at `services/provider/tests.rs:4484` already used the correct pattern (`db.get_provider_by_id`)
- The integration tests were written assuming the import would populate the in-memory config (like `apply_switch` does), but the import function has a different storage contract
