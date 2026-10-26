---
name: cc-switch-app-type-wiring
description: Add a new AppType to cc-switch-tui. Covers Tier 1 structural wiring (enum, match arms, settings) and Tier 2 TUI/CLI feature implementation. Use when adding support for a new AI coding agent to the switcher.
triggers:
  - "add new app type to cc-switch"
  - "add new agent to cc-switch"
  - "cc-switch new AppType"
  - "wire hermes/opencode/opencodex through cc-switch"
---

# Adding a New AppType to cc-switch-tui

Project: `~/work/agent-switch/cc-switch-cli` (Rust/Tauri CLI).
Source root: `src-tauri/src/`.

## Architecture

- `AppType` enum in `app_config.rs`: Claude, Codex, Gemini, OpenCode, OpenClaw, Hermes
- **Additive-mode apps** (OpenCode, OpenClaw, Hermes): use `apiKey`, `baseUrl`, `api`, `headers`, `models` fields directly in `settings_config` JSON. No proxy takeover.
- **Proxy-mode apps** (Claude, Codex, Gemini): use `CommonConfigSnippets`, proxy takeover, more complex config.
- `VisibleApps` in `settings.rs`: bool per app, controls TUI visibility. Default visibility set by `default_visible_app_<name>() -> bool`.
- `hermes_config.rs`: YAML-based config reader for `~/.hermes/config.yaml`. Additive-mode apps use this module for live config read/write.

## Tier 1: Structural Wiring (~30 patches across 4 files)

All changes are mechanical match-arm additions. Pattern: copy the closest existing additive-mode app (OpenClaw) and adapt.

### Files to patch:

1. **`app_config.rs`** (~17 patches):
   - `AppType` enum: add variant
   - `as_str()`, `FromStr`, `all()`, `is_additive_mode()`
   - `McpApps`, `SkillApps`, `VisibleApps`: add `new_field: bool`
   - All match arms: `is_enabled_for`, `set_enabled_for`, `enabled_apps`, `merge_enabled`, `is_empty`
   - `CommonConfigSnippets`: add `new_field: Option<String>` with `get`/`set` arms
   - `PromptRoot`: add `new_field: PromptConfig`
   - `MultiAppConfig::default()`: insert provider manager

2. **`settings.rs`** (~6 patches):
   - `VisibleApps`: add field with `default_visible_app_<name>()` helper
   - `default_visible_apps()`, `is_enabled_for`, `set_enabled_for`
   - `app_order()`: expand array size, add variant
   - Add `get_<name>_override_dir()` helper
   - Add `current_provider_<name>` field + `get_current_provider`/`set_current_provider` arms

3. **`sync_policy.rs`** (~2 patches):
   - `should_sync_live()`: add arm checking config dir existence
   - Add `get_<name>_dir()` helper

4. **`prompt_files.rs`** (~3 patches):
   - Import override dir helper
   - Add arm with prompt filename (e.g., `AGENTS.md` for Hermes)
   - Add `default_<name>_dir()` helper

## Tier 2: TUI/CLI Feature Implementation (~10 files)

For **additive-mode apps**, most logic is identical to OpenClaw. Copy-paste with same field names.

### Files to patch:

1. **`cli/tui/form/provider_state_loading.rs`**: Reuse `populate_openclaw_form` — same fields (apiKey, baseUrl, api, user-agent).

2. **`cli/tui/form/provider_templates.rs`**:
   - Add `PROVIDER_TEMPLATE_DEFS_<NAME>` static (usually just `[Custom]`)
   - Update `provider_builtin_template_defs()` match
   - `provider_sponsor_presets()`: `&[]` unless sponsor presets exist
   - Preset application: copy OpenClaw block

3. **`cli/tui/form/provider_state.rs`**:
   - Add provider fields (same as OpenClaw: ApiProtocol, ApiKey, BaseUrl, UserAgent, Models)
   - Update `!matches!(...)` condition to exclude from CommonConfig (additive mode)

4. **`cli/tui/form/provider_json.rs`**: Full JSON builder — identical to OpenClaw block (remove legacy fields, set apiKey/baseUrl/api/headers/models).

5. **`cli/tui/data.rs`**: API URL extraction — `settings_config.get("baseUrl").or_else(|| settings_config.get("base_url"))`.

6. **`cli/commands/provider_inspect.rs`**: Model fetch — extract `apiKey` from `settings_config`, use `ProviderModelFetchStrategy::Bearer`.

7. **`cli/commands/provider_input.rs`**: Display config — print apiKey (masked), baseUrl, models count.

8. **`services/stream_check/service.rs`**: Use `check_codex_stream` fallback (works for all bearer-auth additive apps).

9. **`services/provider/mod.rs`**: Wire `hermes_config::get_providers()`, `set_provider()`, `read_hermes_config()` etc.

10. **`services/mcp.rs`**: Wire `sync_single_server_to_hermes`, `remove_server_from_hermes`, `import_from_hermes`.
11. **`database/dao/skills.rs`**: Update SQL queries to include `enabled_<name>` column in SELECT, INSERT, UPDATE. See Pitfalls section for exact index shifts.

## Tier 3: Hardcoded App Lists (CRITICAL — easy to miss)

> Full inventory with line numbers: see `references/hardcoded-app-lists.md`

Multiple files contain hardcoded `[AppType::Claude, AppType::Codex, ...]` arrays that iterate over apps. If the new app type is missing from ANY of these, it will be silently skipped — the UI will appear to work but the app won't show in pickers, won't sync to/from DB, won't install skills, etc.

**Search pattern** to find them all:
```bash
grep -rn "AppType::OpenCode," src-tauri/src/ --include="*.rs" | grep -v "=>" | grep -v test
```

**Must-update locations** (as of Hermes addition):

| File | Function/Context | What breaks if missing |
|---|---|---|
| `app_config.rs` | `MCP_PICKER_APPS` const | MCP picker bounds + index→AppType mapping |
| `app_config.rs` | `VISIBLE_PICKER_APPS` const | Visible apps picker bounds + mapping |
| `app_config.rs` | `SKILLS_PICKER_APPS` const | Skills picker bounds + mapping |
| `store.rs` | `export_db_to_multi_app_config` loop | App providers not loaded from DB into config |
| `store.rs` | `persist_multi_app_config_to_db` loop | App providers not saved from config to DB |
| `app_config.rs` | `auto_import_prompt_if_exists` loop | App prompts not auto-imported on first run |
| `cli/tui/runtime_actions/mcp.rs` | MCP toggle sync loop | MCP enable/disable not synced for app |
| `services/skill.rs` | `supported_skill_apps()` | Skills can't be installed for this app |
| `services/skill.rs` | Skill removal loop | Skills not removed from app directory on uninstall |

**Note**: The match arms inside these loops (e.g., `AppType::Hermes => &config.prompts.hermes.prompts`) are usually already added during Tier 1. The bug is the **loop array itself** missing the new variant — the match arm exists but never gets executed.

### Picker Const Arrays (eliminates hardcoded bounds)

Picker navigation bounds and index→AppType mapping are now driven by const arrays in `app_config.rs`:

```rust
pub const MCP_PICKER_APPS: &[AppType] = &[Claude, Codex, Gemini, OpenCode, Hermes];
pub const VISIBLE_PICKER_APPS: &[AppType] = &[Claude, Codex, Gemini, OpenCode, OpenClaw, Hermes];
pub const SKILLS_PICKER_APPS: &[AppType] = &[Claude, Codex, Gemini, OpenCode, Hermes];
```

These are the **single source of truth** for:
- **Render functions** (`ui/overlay/pickers.rs`): pass const directly instead of inline arrays
- **Handler bounds** (`overlay_handlers/pickers.rs`): `CONST.len() - 1` replaces `.min(N)`
- **Index→AppType** (`overlay_handlers/pickers.rs`): `CONST[*selected]` replaces `app_type_for_picker_index(*selected)` for MCP/Skills pickers
- **`four_app_picker_index`** (`helpers.rs`): `.min(MCP_PICKER_APPS.len() - 1)` replaces `.min(3)`

When adding a new app, just append to the relevant const arrays. No other bounds or index mappings need updating.

**Important**: `app_type_for_picker_index()` still uses the GLOBAL ordering (all 6 apps). It's only correct for `VISIBLE_PICKER_APPS` (which includes all apps). For MCP and Skills pickers (which skip OpenClaw), always index into the const array directly.

**AppType must derive Copy** — required for `CONST[index]` to work without `.clone()`. Add `Copy` to the `#[derive(...)]` on the `AppType` enum if not already present. Without it you get `E0508: cannot move out of type [app_config::AppType], a non-copy slice`.

**Tests that assert picker index values will break** when you add a new app to a const array. Specifically, tests like `mcp_apps_picker_from_openclaw_targets_*` assert that OpenClaw (not in MCP picker) clamps to the last valid index. Adding Hermes shifted that from index 3 (OpenCode) to index 4 (Hermes). Search for test names containing `_from_openclaw_targets_` and update both the `selected == N` assertions and the toggled field assertions.

## Pitfalls

- **Existing settings file overrides defaults**: Changing `default_visible_app_<name>() -> true` only affects NEW users. Existing users have the old `false` value persisted in their settings JSON. After changing the default, existing users still won't see the app until they manually enable it in Settings → Visible Apps.
- **Two default paths for VisibleApps — keep them consistent**: `default_visible_app_<name>()` (serde field default, used when the field is missing from JSON) and `default_visible_apps()` (struct-level default, used when the entire `visibleApps` key is missing). If these disagree, behavior depends on whether the user's settings file has a `visibleApps` object at all. Always set both to the same value for a new app.
- **Hardcoded app lists**: See Tier 3 section above. This is the #1 source of "I added the app type but it doesn't show up" bugs. Always run the grep search.
- **Picker index ≠ global index**: MCP and Skills pickers skip OpenClaw, so their index 4 = Hermes, NOT OpenClaw. Never use `app_type_for_picker_index()` for these pickers — use `MCP_PICKER_APPS[selected]` / `SKILLS_PICKER_APPS[selected]` directly. Only `VISIBLE_PICKER_APPS` matches the global ordering.
- **`four_app_picker_index` is misnamed**: Historical name from when there were 4 apps. It now caps at `MCP_PICKER_APPS.len() - 1`. Used by MCP and Skills picker overlay creation to clamp the initial `selected` value for apps not in the picker (e.g., OpenClaw → last valid index).
- **cargo check must run from `src-tauri/`**, not repo root (no `Cargo.toml` at root).
- **Pre-existing lint errors**: `async fn in Rust 2015` warnings in `database/dao/proxy.rs`, `data.rs`, `provider_inspect.rs`, `stream_check/service.rs`. These are NOT caused by new patches — ignore them.
- **84 warnings** baseline — don't panic about warning count.
- **VisibleApps default**: new additive apps should default to `true` for visibility (users expect to see them). Set `default_visible_app_<name>() -> true`.
- **DAO queries lag behind schema**: The schema/migration may already have the `enabled_<name>` column (e.g. v9→v10 migration added `enabled_hermes`), but the DAO layer (`database/dao/skills.rs`) can still hardcode `false`. When adding a new app type, ALWAYS check and update:
  - `get_all_installed_skills` — SELECT + row index mapping (column order shifts, `installed_at` index moves)
  - `get_installed_skill` — same SELECT/index fix
  - `save_skill` — INSERT columns + params
  - `update_skill_apps` — UPDATE SET adds one more `?N` placeholder, WHERE id shifts
  - The `mcp.rs` DAO (`database/dao/mcp.rs`) already handles hermes correctly — use it as the reference pattern.
- **MCP table rendering is hardcoded per-app**: The `render_mcp()` function in `cli/tui/ui/mcp.rs` does NOT use the picker const arrays — it has literal per-app `Cell::from()` calls for the header, data rows, summary counts, and column width constraints. Every new app must be added in all 4 places, PLUS the `tui_mcp_server_counts()` i18n function (in both `i18n.rs` and `texts/config_actions.rs`) needs a new parameter. Missing any of these causes the app to be invisible on the MCP page table. See `references/hardcoded-app-lists.md` #8 for exact steps.
- **Integration test: import writes to DB not config**: `import_openclaw_providers_from_live()` stores providers into `state.db` (SQLite), NOT `state.config` (in-memory `MultiAppConfig`). Tests must assert via `state.db.get_provider_by_id()` / `state.db.get_provider_ids()`, not `state.config.read().get_manager()`. The in-memory config stays at `MultiAppConfig::default()` (empty) after import.
- **YAML strings**: User prefers no quotes unless necessary.
- **Commit style**: Conventional Commits — `feat(scope): subject`, English, lowercase start, no period.
- **`pub use` re-export visibility**: `mod config;` in lib.rs is *private* — callers must use `cc_switch_lib::func_name` (the re-exported path), NOT `cc_switch_lib::config::func_name` (the module-qualified path). The latter fails with `E0603: module config is private`. When adding any new public function to a private module, you MUST add it to the `pub use` block in `lib.rs` to export it to the bin target.
- **Patch tool + `pub use` blocks — accidental removal**: When patching a `pub use` block in `lib.rs` to add new re-exports, the `old_string` and `new_string` must both contain ALL existing items in that block. If `new_string` drops an existing re-export (e.g., `pub use database::{Database, FailoverQueueItem};`), the entire crate breaks with `E0432: unresolved import crate::Database` across multiple files. Always `grep` for each re-exported name after patching lib.rs to verify nothing was lost.
- **`--help` exits during `Cli::parse()`, not in `main()` body**: clap's `--help` and `--version` exit the process during argument parsing, BEFORE any code in `main()` after `Cli::parse()` runs. Any startup-side-effect code (migration, init, health checks) will NOT execute for `--help`/`--version`. Always test startup hooks with a real command (e.g., `config show`, `provider list`), never with `--help`.\n- **Startup stderr messages buried by compilation warnings**: In debug builds, 84+ `rustc` warnings printed to stderr can bury a single-line migration/init message. Users testing with `cargo run` may not see the message at all. The code is working — it's just hard to spot in the noise. Build release (`cargo build --release`) or filter warnings (`2>/dev/null`) when verifying startup output.\n- **Debugging silent startup functions**: When a startup function that should produce output silently returns nothing, add `eprintln!` trace at each guard condition to find which one is blocking. Common guards: env var check, directory existence, marker file existence, non-empty check.\n- **Patch tool + struct removal**: When using `patch` with `old_string` that spans past the end of a struct/block you want to ADD before (i.e. your `new_string` inserts code before an existing struct definition), verify the original struct/block wasn't accidentally deleted. The `patch` tool replaces the entire `old_string` range, so if your `old_string` includes `struct Foo { ... }` at the end but your `new_string` doesn't re-include it, `Foo` is gone. Always check `grep` for the struct name after patching.
- **i18n texts module is INLINE — `cli/i18n/texts/` directory is dead code**: The actual `texts` module lives inline in `cli/i18n.rs` as `pub mod texts { ... }` from line 138 through line ~8833 (a massive 8900-line file). The separate `cli/i18n/texts/` directory with `core.rs`, `menu_skills.rs`, etc. is NOT part of the module tree — it contains duplicate/legacy function definitions and is never compiled. When adding new `tui_*` i18n functions, ALWAYS add them to the inline module inside `i18n.rs`, NEVER to `cli/i18n/texts/core.rs` or any other file under `cli/i18n/texts/`. Adding them to the dead directory silently compiles with no errors but the functions won't be found at call sites (runtime `E0425: cannot find function in module texts`).

## Verification

```bash
cd src-tauri && cargo check          # compile check
cd src-tauri && cargo test --lib     # unit tests (expect ~1369 passed)
cargo test --test import_export_sync # integration tests (expect ~31 passed)
grep -rn "TODO.*<Name>" src-tauri/src/ --include="*.rs"  # verify no TODOs remain
grep -n "hermes: false\\|<name>: false" src-tauri/src/database/dao/skills.rs  # verify DAO not hardcoded
# CRITICAL: verify no hardcoded app lists missing the new type
grep -rn "AppType::OpenCode," src-tauri/src/ --include="*.rs" | grep -v "=>" | grep -v test
# Every hit should also contain AppType::<NewApp> nearby
# MCP table: verify the new app column appears in the rendered table
grep -A20 "fn render_mcp" src-tauri/src/cli/tui/ui/mcp.rs | grep "<name>"
```

## Reference: Provider List Rendering

See `references/provider-rendering.md` — marker logic, app classification groups, key bindings, and right-aligned current-provider title pattern for `render_providers()`.

## Reference: Hermes Wiring Summary

Hermes was added as the 6th AppType. Key decisions:
- Additive mode (like OpenClaw)
- Config dir: `~/.hermes/`
- Prompt file: `AGENTS.md`
- Default visible: `true`
- TUI color: `LightYellow` / `BrightYellow`
- Form fields: identical to OpenClaw (reuse `populate_openclaw_form`)
- JSON builder: identical to OpenClaw
- Model fetch: bearer auth via `apiKey`
- Stream check: `check_codex_stream` fallback
- MCP: `hermes_config` module for YAML read/write

## Reference: Config Directory Layout

See `references/config-directory.md` — default config dir is `~/.cc-switch-tui/`, overridable via `CC_SWITCH_TUI_CONFIG_DIR`. Legacy `~/.cc-switch/` data is auto-migrated on first run.
