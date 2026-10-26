---
name: adding-rust-enum-variant
description: Systematically add a new variant to a Rust enum used in match statements across a large codebase. Covers enum + methods + structs + settings + color maps + DAO initialization sites.
trigger:
  - User asks to add a new enum variant (e.g. new app type, new status, new config type)
  - Need to add support for a new application/client/platform in an existing Rust project
  - Cargo check reports many E0004 non-exhaustive pattern errors after adding a variant
---

# Adding a Rust Enum Variant — Systematic Approach

When a Rust enum is used in match statements across dozens of files, adding a new variant requires touching every single match site. This skill captures the order and pitfalls.

## Pre-flight

1. **Create a feature branch** — `git checkout -b feat/<variant-name>`
2. **Run `cargo check`** to establish baseline — confirm zero errors before starting
3. **Search for all match sites** — `grep -rn "AppType::" src/ | grep -v "test"` (adjust for your enum name)

## Step-by-step Order

### Phase 1: Core type definitions (app_config.rs or equivalent)

1. **Enum definition** — add the variant
2. **`as_str()`** — return lowercase string name
3. **`is_additive_mode()`** or similar boolean classifiers — decide if new variant qualifies
4. **`all()` iterator** — add to the array
5. **`FromStr`** — add match arm + update error message allowed values

### Phase 2: App-tracking structs

6. **`McpApps` / `SkillApps`** — add `pub hermes: bool` field
7. **All methods on these structs** — `is_enabled_for`, `set_enabled_for`, `enabled_apps`, `is_empty`, `merge_enabled`
8. **`CommonConfigSnippets`** — add `Option<String>` field + `get()` + `set()` methods
9. **`PromptRoot`** — add `PromptConfig` field

### Phase 3: Config/settings

10. **`MultiAppConfig::default()`** — insert into apps HashMap
11. **`VisibleApps`** — add field + default function + `is_enabled_for`/`set_enabled_for` + `app_order()` array (update array size)
12. **`AppSettings`** — add `config_dir: Option<String>` + `current_provider: Option<String>` fields + Default impl + `normalize_common()` normalization
13. **Override dir getter** — `get_<variant>_override_dir()` function

### Phase 4: Service layer

14. **`sync_policy::should_sync_live()`** — add branch checking if config dir exists
15. **`prompt_files::prompt_file_path()`** — add branch returning dir + filename
16. **`get_current_provider()` / `set_current_provider()`** — add branches
17. **Color maps** — `inquire_color_for_app()` + `highlight_color_for_app()` or equivalent

### Phase 5: DAO / database

18. **DAO struct initialization sites** — search for `StructName { field1, field2, ... }` patterns and add the new field (usually `false` or `None`)
19. **Database schema** — if needed, add column + migration

### Phase 6: Exhaustive cleanup (batch approach)

20. **Run `cargo check`** — extract deduplicated error locations:
    ```bash
    cargo check 2>&1 | grep "error\[E0004\]" -A 3 | grep "^\s*-->" | sort -u
    ```
    The `sort -u` collapses multiple errors on the same line into one entry.

21. **Group errors by file** — fix all errors in one file before moving to the next. Read context around each error line (offset=line-3, limit=15) to understand the match pattern.

22. **Categorize match arms** before writing code:
    - **`unreachable!()`** — code paths that should never be reached (e.g. additive-mode apps in switch/delete operations that are handled earlier via a separate branch)
    - **Merged with similar variants** — `AppType::OpenCode | AppType::OpenClaw | AppType::Hermes =>` for generic handling where behavior is identical
    - **`todo!()` / placeholder returns** — features pending implementation in a future phase; use `Err(AppError::localized(...))` for functions returning `Result` so the error message is informative
    - **Default values** — `false`, `None`, empty string, empty `json!({})` for initialization/defaults
    - **Distinct behavior** — unique logic per variant (e.g. reading from a specific config path)

23. **Batch-fix with `execute_code`** — use a loop to read all error locations in a file at once, then apply targeted patches. Avoids re-reading the file for each error.

24. **Run `cargo check` again** — iterate until zero errors

## Pitfalls

- **Const arrays for subset iteration.** When different UI components iterate over different subsets of the enum (e.g., some pickers skip certain variants), extract those subsets into `pub const` slices (`&[EnumType]`). This eliminates hardcoded `.min(N)` bounds and inline arrays that must be updated manually. The enum must derive `Copy` for direct slice indexing (`CONST[i]`) to work without `.clone()`. Without `Copy`, you get `E0508: cannot move out of non-copy slice`.

- **Commit in stages.** The user prefers atomic commits: first commit for core types + provider/config, second commit for CLI/TUI/services. This keeps the git history clean and reviewable. Don't try to fix everything in one giant commit.

- **Patch tool breaks nested match arms.** When the code has `match (app, mode) { ... }` or nested closures, the patch tool's old_string matching fails silently or creates invalid syntax. Use `execute_code` with explicit old_string/new_string pairs for reliability.

- **`update_settings(settings)` gets silently dropped.** When patching `set_current_provider` or similar functions, the final `update_settings(settings)` call can get eaten by the patch. Always verify the function still ends with the save call after patching.

- **Struct initialization sites are easy to miss.** `SkillApps { claude: ..., codex: ..., ... }` patterns in DAO files don't use match statements — they won't trigger E0004. They trigger E0063 (missing field) instead. Search for both error types.

- **Array size in `app_order()` must be updated.** If it was `[AppType; 5]`, change to `[AppType; 6]`.

- **Default visibility matters.** New apps typically default to `false` in `VisibleApps` and `default_visible_apps()` unless the user specifies otherwise.

- **Color choice for new app.** Pick a distinct color early (e.g. `LightYellow`/`BrightYellow`) to avoid confusion with existing apps.

- **`git checkout -- <file>` for recovery.** If a patch creates broken syntax, restore the file and redo with smaller, more targeted patches.

## Verification

```bash
cargo check 2>&1 | tail -5
# Should show 0 errors
```

## Reference

- `references/cc-switch-cli-hermes-example.md` — full worked example: adding `AppType::Hermes` to cc-switch-cli, 65+ E0004 errors across 20+ files, with categorized match arm patterns.

Session: cc-switch-cli adding `AppType::Hermes` — 65 E0004 errors + 2 E0063 errors across 28 files in 2 commits.
