# VS Code MCP Integration

Sharing MCP servers configured in Hermes with VS Code (Copilot, Roo Cline, Cursor).
MCP is transport-agnostic — each client spawns its own subprocess from config, so only
the *configuration* needs to be shared, not the runtime.

## Format Differences

Three VS Code tools, three JSON schemas, all derived from the same Hermes YAML:

```
# Hermes (YAML) — canonical source
mcp_servers:
  nixos:
    command: uvx
    args: [mcp-nixos]

# Copilot — extra "type" field + "servers" key
{"servers": {"nixos": {"type": "stdio", "command": "uvx", "args": ["mcp-nixos"]}}}

# Roo Cline — "mcpServers" key, no type field
{"mcpServers": {"nixos": {"command": "uvx", "args": ["mcp-nixos"]}}}

# Cursor — same format as Roo Cline
{"mcpServers": {"nixos": {"command": "uvx", "args": ["mcp-nixos"]}}}
```

| Feature | Copilot | Roo Cline | Cursor |
|---------|---------|-----------|--------|
| JSON key | `servers` | `mcpServers` | `mcpServers` |
| `type` field | Required (`"stdio"`) | None | None |
| `env` support | Yes | Yes | Yes |
| Preserves extra fields | Yes (gallery, version) | Yes | Yes |

## File Paths

### Local VS Code (macOS)

| Tool | Path |
|------|------|
| Copilot | `~/Library/Application Support/Code/User/mcp.json` |
| Roo Cline | `~/Library/Application Support/Code/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json` |
| Cursor | `~/.cursor/mcp.json` |

### VS Code Server Remote (Linux target)

| Tool | Path |
|------|------|
| Copilot | `~/.vscode/mcp.json` |
| Roo Cline | `~/.vscode-server/data/User/globalStorage/rooveterinaryinc.roo-cline/settings/mcp_settings.json` |
| Cursor | `~/.cursor/mcp.json` |

Note: macOS remote targets (SSH into a Mac) reuse the local VS Code paths, not `.vscode-server/`.

## Sync Script

Located at `~/work/zzzzzzz-temp-nix+lua/sync-mcp-to-vscode.py`.

Usage:
```
## Preview all targets
python3 sync-mcp-to-vscode.py

## Write all targets
python3 sync-mcp-to-vscode.py --write

## Single target
python3 sync-mcp-to-vscode.py --write --target copilot

## Linux remote VS Code Server
python3 sync-mcp-to-vscode.py --write --remote
```

Behavior:
- Reads `~/.hermes/config.yaml` → `mcp_servers` section
- Merges with existing config (preserves non-Hermes servers like `markitdown`)
- Updates Hermes-originated servers in-place (preserves extra fields like `gallery`)
- Backs up target files before overwriting (timestamped `.bak.*`)
- Carries `env` variables (GitHub PAT, etc.) from Hermes config

## Platform-Specific Considerations

When syncing to a remote machine where Hermes MCP servers aren't installed:

| Server | Issue | Fix |
|--------|-------|-----|
| qt-rules | Path is macOS-hardcoded | `uv tool install git+https://github.com/lpmwfx/QT-RulesMCP.git` on remote; use that path |
| playwright | Needs browser | `npx playwright install chromium` on headless Linux |
| github | Needs PAT + gh CLI | Copy token to remote config |
| nixos/context7/sequential-thinking | Universal | Works anywhere npx/uvx are available |

## Pitfalls

- Copilot's `inputs` array in mcp.json must be preserved during merge (the script handles this)
- GitHub token appears redacted in Hermes tool output but the actual value in `config.yaml` is the real token — the sync script passes the real value through
- VS Code Server remote paths differ from local paths on Linux but are identical on macOS remote targets
- Restart VS Code (or reload window) after writing MCP config for changes to take effect
