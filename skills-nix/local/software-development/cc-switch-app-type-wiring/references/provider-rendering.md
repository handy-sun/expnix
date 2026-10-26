# Provider List Rendering Architecture

File: `src-tauri/src/cli/tui/ui/providers.rs`

## App Classification in Provider Rendering

The `render_providers()` function classifies apps into three groups for markers, key bindings, and current-provider display:

| Group | Apps | Marker | Switch Key | Detail Key |
|---|---|---|---|---|
| Config-membership | OpenClaw | `*` default / `+` in config / `""` rest | `s` (add/remove) | Enter |
| Config-membership | OpenCode | `+` in config / `""` rest | `s` (add/remove) | Enter |
| Current-provider | Claude, Codex, Gemini, Hermes | ✓ current / `" "` rest | Space | Enter |

Even though Hermes is additive-mode (like OpenClaw), it's in the Current-provider group because it has a "current provider" concept stored in the DB, unlike OpenCode/OpenClaw which manage config membership via `is_in_config`.

## Marker Logic (`lines 96-116`)

```
OpenClaw:  fetch_openclaw_providers  →  `*` / `+` / `""`
OpenCode:  fetch_opencode_providers  →  `+` / `""`
Other (failover ON):  failover_queue  →  ✓ / `" "`
Other (failover OFF): row.is_current →  ✓ / `" "`
```

## Right-Aligned Current Provider Title

Added via `Block::title(Line::from(title).right_aligned())`. Only shown for apps in the Current-provider group. Uses `data::provider_display_name()` to get the display name. Falls back to "None" / "无" when no current provider is set.

Pattern:
```rust
let has_current_concept = !matches!(app.app_type, AppType::OpenCode | AppType::OpenClaw);
let right_title = if has_current_concept {
    let name = data.providers.rows.iter()
        .find(|r| r.is_current)
        .map(|r| data::provider_display_name(&app.app_type, r))
        .unwrap_or_else(|| texts::tui_provider_none().to_string());
    Some(Line::from(Span::styled(
        format!("{}: {}", texts::tui_label_current(), name),
        Style::default().fg(theme.accent),
    )).right_aligned())
} else {
    None
};
```

## i18n Functions

All in `cli/i18n.rs` inline `pub mod texts { ... }` (NOT `cli/i18n/texts/` directory — dead code):
- `tui_label_current()` → "Current" / "当前"
- `tui_provider_none()` → "None" / "无"
- `tui_marker_active()` → "✓"
- `tui_marker_inactive()` → " "
