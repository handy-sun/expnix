# cc-switch-cli: Adding AppType::Hermes — Full Example

## Context

Rust/Tauri project (cc-switch-cli) adding a new app type `Hermes` to the `AppType` enum. The enum is used in ~50+ match statements across 20+ files. Hermes is an "additive mode" app (like OpenCode/OpenClaw) — it manages its own config files rather than using a single-provider proxy model.

## Error Progression

- Initial: 65 E0004 + 2 E0063 errors
- After Phase 1-5 (core types): 62 E0004 remaining
- After provider/config batch: 45 E0004 remaining
- After CLI/TUI batch: 0 errors
- Two commits: `0ef8192` (core types + provider/config, +84/-6) then `e70d2c9` (CLI/TUI/services, +65/-6)

## Match Arm Patterns Used

### 1. `unreachable!()` — for additive-mode switch/delete paths

Used in `prepare_switch`, `snapshot_from_live`, and similar functions where additive-mode apps are handled by an earlier `if app_type.is_additive_mode()` branch:

```rust
AppType::OpenCode => unreachable!("additive mode handled above"),
AppType::OpenClaw => unreachable!("additive mode handled above"),
AppType::Hermes => unreachable!("additive mode handled above"),
```

### 2. Merged with similar variants — for generic handling

Used in validation, common config parsing, and error formatting:

```rust
AppType::OpenCode | AppType::OpenClaw | AppType::Hermes => {
    parse_json_object_snippet(app_type, snippet, false)?;
}
```

### 3. `todo!()` or placeholder returns — for Tier 2 features

Used when the config module (`hermes_config.rs`) doesn't exist yet:

```rust
AppType::Hermes => {
    // TODO: Implement Hermes config reading in Tier 2
    json!({})
}
```

For `Result` returns, use a descriptive error instead of `todo!()`:

```rust
AppType::Hermes => {
    Err(AppError::localized(
        "provider.hermes.api_key.missing",
        "Hermes API Key 提取尚未实现",
        "Hermes API key extraction not yet implemented",
    ))
}
```

### 4. Default values — for initialization

```rust
AppType::Hermes => config.prompts.hermes.prompts = prompts.into_iter().collect(),
```

### 5. Empty/no-op — for functions where action isn't needed

```rust
AppType::Hermes => {
    let _ = provider_snapshot;
}
```

## Batch Fix Strategy

1. Get all error locations: `cargo check 2>&1 | grep "error\[E0004\]" -A 3 | grep "^\s*-->" | sort -u`
2. Group by file (e.g. `services/provider/mod.rs` had 8 errors, `common_config.rs` had 6)
3. For each file, read all error locations in one batch using `execute_code` with a loop
4. Fix all errors in one file before moving to the next
5. Use `patch()` with targeted old_string/new_string pairs

## Gotchas from This Session

1. **`read_live_settings` returns `Result<Value, AppError>`** — the Hermes branch needs `Ok(json!({}))`, not just `json!({})`. The `json!()` macro produces a `Value`, but the function expects a `Result`.

2. **`remove_server_from_*` returns `()`** — these functions don't return a count. The Hermes branch needs an empty block `{}`, not `0`.

3. **MCP functions that don't exist yet** — when the config module (`hermes_config.rs`) hasn't been implemented, don't call `mcp::sync_single_server_to_hermes()` or `mcp::remove_server_from_hermes()`. Use empty blocks instead.

4. **Template defs return `&[]` for new apps** — `provider_builtin_template_defs()` and `provider_sponsor_presets()` return static slices. For a new app with no templates yet, return `&[]`.

5. **`DRACULA_YELLOW` already exists in theme.rs** — don't define a new color constant; use the existing one.

6. **Skills dir follows `~/.<app>/skills` pattern** — for Hermes: `~/.hermes/skills`. The override dir getter follows `get_<app>_override_dir()`.

7. **Commit in stages** — the user prefers atomic commits. First commit: core types + provider/config. Second commit: CLI/TUI/services. This keeps the git history clean and reviewable.

## Files Modified (28 files total)

### Commit 1: Core types + provider/config (12 files)
| File | Errors | Pattern |
|------|--------|---------|
| `app_config.rs` | 12+ | Core type definitions, struct fields, method arms |
| `settings.rs` | 8+ | Config dir fields, provider fields, getter/setter arms |
| `services/provider/mod.rs` | 8 | Mix of unreachable!, todo!, and merged arms |
| `services/provider/common_config.rs` | 6 | Merged with OpenCode/OpenClaw |
| `services/provider/live.rs` | 3 | New LiveSnapshot::Hermes variant + capture/restore |
| `services/provider/usage.rs` | 2 | Descriptive error returns |
| `services/prompt.rs` | 5+ | Merged with existing patterns |
| `services/mcp.rs` | 1 | Empty block for sync |
| `services/config.rs` | 1 | Empty block for sync_live |
| `store.rs` | 2 | Prompt persistence |
| `proxy/providers/mod.rs` | 2 | Adapter mapping |
| `deeplink/provider.rs` | 1 | Settings builder |
| `cli/ui/colors.rs` | 2 | Color maps |

### Commit 2: CLI/TUI/services (16 files)
| File | Errors | Pattern |
|------|--------|---------|
| `cli/commands/config_common.rs` | 1 | Merged with OpenCode/OpenClaw |
| `cli/commands/mcp.rs` | 1 | Return 0 for no-op |
| `cli/commands/provider_input.rs` | 2 | Empty block for display + Ok(json!({})) for config |
| `cli/commands/provider_inspect.rs` | 1 | Descriptive error return |
| `cli/tui/data.rs` | 2 | None for takeover + None for API URL |
| `cli/tui/form/provider_json.rs` | 3 | Empty block + merged with OpenCode/OpenClaw |
| `cli/tui/form/provider_state.rs` | 1 | Empty block for fields |
| `cli/tui/form/provider_state_loading.rs` | 1 | Reuse OpenClaw form as placeholder |
| `cli/tui/form/provider_templates.rs` | 3 | Return &[] for templates + empty block for preset |
| `cli/tui/runtime_actions/helpers.rs` | 2 | Return Ok(0) for MCP import + "Hermes" display name |
| `cli/tui/theme.rs` | 1 | DRACULA_YELLOW accent color |
| `services/skill.rs` | 2 | ~/.hermes/skills path |
| `services/stream_check/provider_extract.rs` | 3 | Descriptive error returns + default model |
| `services/stream_check/service.rs` | 1 | Reuse check_codex_stream as placeholder |

## LiveSnapshot Enum Pattern

When adding a variant to an enum like `LiveSnapshot` that has a `capture` and `restore` method:

1. Add the variant to the enum with appropriate fields
2. Add `capture` arm (read from config files)
3. Add `restore` arm (write to config files)

```rust
LiveSnapshot::Hermes { config } => {
    // TODO: Implement Hermes live snapshot restore in Tier 2
    let _ = config;
}
```
