# Config Directory Layout

cc-switch-tui (this project) uses `~/.cc-switch-tui/` by default.
The upstream cc-switch GUI uses `~/.cc-switch/` (via Tauri app-store path resolution).

These are separate directories — no conflict with upstream.

## Default Directory: ~/.cc-switch-tui/

| Path | Purpose |
|------|---------|
| `~/.cc-switch-tui/cc-switch.db` | SQLite database (schema v10) |
| `~/.cc-switch-tui/settings.json` | User settings |
| `~/.cc-switch-tui/skills/` | Skill source files (SSOT) |
| `~/.cc-switch-tui/backups/` | Config backups (auto-rotation, keep 10) |
| `~/.cc-switch-tui/config.json` | Legacy JSON (migration/import only) |
| `~/.cc-switch-tui/state-mutation.lock` | Concurrency lock |

## Env Var Override

Two env vars control the config directory, in priority order:

1. **`CC_SWITCH_TUI_CONFIG_DIR`** (current, preferred)
2. **`CC_SWITCH_CONFIG_DIR`** (deprecated, still works but prints `eprintln!` warning)

If neither is set, defaults to `~/.cc-switch-tui/`.

```bash
export CC_SWITCH_TUI_CONFIG_DIR="$HOME/.cc-switch-custom"
```

## Legacy Migration (~/.cc-switch/ → ~/.cc-switch-tui/)

On first run (before the rename from cc-switch-cli to cc-switch-tui), the project used `~/.cc-switch/`. An automatic one-time migration copies old data to the new directory:

- **Two-phase design**: Pre-check + interactive prompt BEFORE any config access, then auto-migrate inside `get_app_config_dir()` on user approval.
- **Implementation**:
  - `config.rs::migration_guard()` — shared guard logic (env var override, directory existence, marker check, non-empty check)
  - `config.rs::check_legacy_config_dir_migration_needed()` — returns `true` if migration is pending
  - `config.rs::skip_legacy_config_dir_migration()` — writes `.migrated-from-cc-switch` marker to suppress future prompts
  - `config.rs::migrate_legacy_config_dir_if_needed()` — performs actual copy (called from `get_app_config_dir()`)
  - `main.rs::prompt_legacy_config_migration()` — stdin Y/n dialog, runs before `initialize_startup_state_if_needed()`
  - `lib.rs` — re-exports `check_legacy_config_dir_migration_needed` and `skip_legacy_config_dir_migration`
- **User chooses Y (default)**: Auto-migrate proceeds inside `get_app_config_dir()` on next call.
- **User chooses N**: Marker written, `get_app_config_dir()` skips migration permanently.
- **Guard**: Marker file `~/.cc-switch-tui/.migrated-from-cc-switch` prevents re-migration (and re-prompting).
- **Old dir must exist and be non-empty**.
- **Non-destructive**: Old `~/.cc-switch/` is fully preserved.
- **backups/**: Only 3 most recent by mtime are copied (not all 10).
- **All other files/dirs**: Copied recursively (skips symlinks).
- **Errors**: Logged to stderr, never block startup.

**Testing note**: The migration prompt runs BEFORE `Cli::parse()` completes for `--help`/`--version` — clap exits during `Cli::parse()`, so `prompt_legacy_config_migration()` in `main()` body can't run. Use any real command: `config show`, `provider list`, bare `cc-switch-tui` (interactive mode). In debug builds (`cargo run`), the 84+ rustc warnings on stderr may bury the migration messages; filter with `2>/dev/null` or build release.

## Upstream Sharing (Historical)

Before the rename, cc-switch-cli and upstream cc-switch (GUI) shared `~/.cc-switch/` by default. This is no longer a concern — they now use separate directories.
