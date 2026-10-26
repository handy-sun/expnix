# Hardcoded App Lists — Full Inventory

When adding a new AppType, every one of these locations must include the new variant.
Discovered during Hermes addition — missing ANY of these causes silent "app doesn't show up" bugs.

## Search Command

```bash
grep -rn "AppType::OpenCode," src-tauri/src/ --include="*.rs" | grep -v "=>" | grep -v test
```

## Locations (Hermes-era inventory)

### Picker Const Arrays (`app_config.rs`) — SINGLE SOURCE OF TRUTH

These const arrays replaced the inline arrays that used to live in render functions.
They drive both rendering AND handler logic (bounds + index→AppType mapping).

1. **`MCP_PICKER_APPS`**: [Claude, Codex, Gemini, OpenCode, Hermes] — no OpenClaw
2. **`VISIBLE_PICKER_APPS`**: [Claude, Codex, Gemini, OpenCode, OpenClaw, Hermes] — all apps
3. **`SKILLS_PICKER_APPS`**: [Claude, Codex, Gemini, OpenCode, Hermes] — no OpenClaw

**Used by:**
- `cli/tui/ui/overlay/pickers.rs` render functions (pass const to `render_apps_picker_overlay`)
- `cli/tui/app/overlay_handlers/pickers.rs` handlers:
  - `.min(CONST.len() - 1)` for Down key bounds
  - `CONST[*selected]` for index→AppType on toggle ('x'/space)
- `cli/tui/app/helpers.rs`: `four_app_picker_index` uses `MCP_PICKER_APPS.len() - 1`

### DB↔Config Sync (`store.rs`)

4. **`export_db_to_multi_app_config`** (~line 207): Loads providers/prompts/snippets from DB into `MultiAppConfig`
5. **`persist_multi_app_config_to_db`** (~line 257): Saves providers/prompts/snippets from config back to DB

### Prompt Import (`app_config.rs`)

6. **`auto_import_prompt_if_exists`** (~line 677): Auto-imports prompt files on first run

### MCP Toggle (`cli/tui/runtime_actions/mcp.rs`)

7. **MCP app toggle sync loop** (~line 55): Syncs MCP server enable/disable per app

### MCP Table Rendering (`cli/tui/ui/mcp.rs`)

8. **MCP table columns**: The `render_mcp()` function hardcodes per-app header cells, data-row cells, summary counts, and column widths. Every app MUST have a column added:
   - Header: add `Cell::from(crate::app_config::AppType::Hermes.as_str())`
   - Data rows: add `Cell::from(if row.server.apps.hermes { ... })`
   - Summary bar: add a 5th `.filter(|row| row.server.apps.hermes).count()` argument to `tui_mcp_server_counts()`
   - Column widths: add a 6th constraint (e.g. `Constraint::Length(9)`) and reduce `Percentage(50)` → `Percentage(40)`
   - **I18N**: `tui_mcp_server_counts()` in both `i18n/texts/config_actions.rs` and `i18n.rs` needs a 5th `hermes: usize` parameter added to the format strings
   - Missing any of these causes Hermes to be invisible in the MCP page table

### Skill Service (`services/skill.rs`)

9. **`supported_skill_apps()`** (~line 388): Which apps can have skills installed
10. **Skill removal loop** (~line 950): Removes skill files from app directories on uninstall

## Pattern

Each location has an array like:
```rust
for app in [
    AppType::Claude,
    AppType::Codex,
    AppType::Gemini,
    AppType::OpenCode,
    AppType::OpenClaw,
    // AppType::Hermes,  <-- MUST ADD
] {
```

And usually a match arm inside the loop body that IS already wired (added in Tier 1).
The bug is the loop array missing the variant — the match arm exists but never executes.

## Index Mapping Pitfall

`app_type_for_picker_index()` in `helpers.rs` uses GLOBAL ordering:
```
0=Claude, 1=Codex, 2=Gemini, 3=OpenCode, 4=OpenClaw, 5=Hermes
```

But MCP/Skills pickers skip OpenClaw, so their actual layout is:
```
0=Claude, 1=Codex, 2=Gemini, 3=OpenCode, 4=Hermes
```

**Never use `app_type_for_picker_index()` for MCP or Skills pickers.**
Use `MCP_PICKER_APPS[selected]` or `SKILLS_PICKER_APPS[selected]` directly.

Only `VISIBLE_PICKER_APPS` matches the global ordering (it includes all apps).
