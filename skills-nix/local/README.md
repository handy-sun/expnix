# local/

The 45 skills that have no usable upstream, plus nine Hermes toolkit skills
copied out of its 271 MB runtime repository. Every skill is one directory with
a `SKILL.md` at the top:

```text
local/
├── nix-flake-development/SKILL.md
├── rust-test-isolation/SKILL.md
└── ...
```

Two rules:

- **Flat only.** No category directories and no skill inside another skill.
  The deployed tree mirrors the source layout, and several agents (dsh reads
  `~/.agents/skills/<name>/SKILL.md`) only scan one level below their skills
  root, so a nested layout would be invisible to them. Keep the category in the
  file name or in the front matter instead.
- **Upstream first.** If the skill exists in a public repository, wire that
  repository up in `../catalog.nix` instead of copying the content here. The
  Hermes copies are the exception: its repository is 271 MB of agent runtime,
  so nine small tool skills were copied instead of adding the input.

## What is in here

### Nix 与基础设施

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `nix-flake-development` | >- |  |
| `nix-module-capability-detection` | Write or review cross-platform Nix modules that must work in NixOS, nix-darwin, Home Manager, or mixed modu… |  |
| `nix-flake-ci` | Optimize CI and binary cache for NixOS/nix-darwin/home-manager flakes. |  |
| `expnix-workflow` | Works in the expnix Nix flake repository. |  |
| `skills-nix-maintenance` | Maintains the agent skill catalog in this expnix checkout. |  |

### CI 与桌面打包

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `desktop-app-ci` | CI/CD for native desktop applications (Qt, C++, Rust/Tauri, Swift/Electron). |  |
| `desktop-app-qt6-ci` | CI/CD for Qt6 desktop applications. |  |
| `cpp-code-review` | Review C/C++ codebases for bugs, vulnerabilities, and quality issues. |  |

### Rust

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `adding-rust-enum-variant` | Systematically add a new variant to a Rust enum used in match statements across a large codebase. |  |
| `cargo-dependency-update` | Update Rust crate dependencies in Cargo.toml. |  |
| `rust-pre-commit-hook` | Set up a git pre-commit hook for Rust projects that runs rustfmt on staged .rs files. |  |
| `rust-struct-field-propagation` | Add a new field to a Rust struct and propagate it to all usages across the codebase, including tests. |  |
| `rust-test-isolation` | >- |  |

### C 与 Shell

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `c-development` | Guidelines for C/C++ development — code style, comments, compilation, and project conventions. |  |
| `shell-scripting` | Guidelines for writing shell scripts — style, output language, structure, and common patterns. |  |

### GitHub

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `github-auth` | GitHub auth setup: HTTPS tokens, SSH keys, gh CLI login. | gh/SSH 指南；脚本会回退读 `~/.hermes/.env` |
| `github-code-review` | Review PRs: diffs, inline comments via gh or REST. | 同上 |
| `github-issues` | Create, triage, label, assign GitHub issues via gh or REST. | 同上 |
| `github-pr-workflow` | GitHub PR lifecycle: branch, commit, open, CI, merge. | 同上 |
| `github-release-management` | Manage GitHub releases triggered by tag pushes. |  |
| `github-repo-management` | Clone/create/fork repos; manage remotes, releases. | 同上 |

### MCP 与事件

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `native-mcp` | MCP client: connect servers, register tools (stdio/HTTP). | Hermes 专用：讲的是 `~/.hermes/config.yaml` 的 mcp_servers |
| `mcporter` | List, auth, and call MCP servers/tools from the terminal. | 从 Hermes 复制 |
| `webhook-subscriptions` | Webhook subscriptions: event-driven agent runs. | Hermes 专用：`hermes webhook` 与 gateway |

### 调试与排查

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `node-inspect-debugger` | Debug Node.js via --inspect + Chrome DevTools Protocol CLI. | 从 Hermes 复制；含 Hermes ui-tui 调试小节 |
| `python-debugpy` | Debug Python: pdb REPL + debugpy remote (DAP). | 从 Hermes 复制；含 Hermes gateway 调试小节 |
| `systematic-debugging` | 4-phase root cause debugging: understand bugs before fixing. |  |
| `hdd-pending-sector-repair` | Diagnose and repair HDD Current_Pending_Sector issues: locate failing LBA via SMART self-test log, map it t… | 通用运维流程；提到 Hermes 的安全限制 |

### 开发工作流

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `spike` | Throwaway experiments to validate an idea before build. | 从 Hermes 复制（改编自 gsd-build/get-shit-done） |
| `requesting-code-review` | Pre-commit review: security scan, quality gates, auto-fix. | 从 Hermes 复制；含 Hermes 一次性会话说明 |
| `writing-plans` | Write implementation plans: bite-sized tasks, paths, code. |  |
| `workflow-skill-architect` | Use when creating or refactoring a skill for a complex multi-step task, especially when an existing skill h… |  |
| `release-skills` | Universal release workflow. |  |
| `codebase-inspection` | Inspect codebases w/ pygount: LOC, languages, ratios. | 从 Hermes 复制 |

### 文档与写作

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `project-docs` | Maintain project documentation — CLAUDE.md generation, bilingual READMEs, and docs sync. |  |
| `design-md-init` | > |  |
| `domain-name-brainstormer` | Generates creative domain name ideas for your project and checks availability across multiple TLDs (.com, .… |  |
| `awesome-cv-customization` | Customize the Awesome-CV LaTeX resume/CV template — fonts, sizes, colors, layout. |  |

### 运维与自托管

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `docker-compose-selfhost` | Deploy third-party Docker services to a local compose directory. |  |
| `kanban-orchestrator` | Decomposition playbook + anti-temptation rules for an orchestrator profile routing work through Kanban. | Hermes 专用：Hermes Kanban dispatcher / profile |
| `kanban-worker` | Pitfalls, examples, and edge cases for Hermes Kanban workers. | Hermes 专用：KANBAN_GUIDANCE / kanban_* 工具 |
| `find-nearby` | Find nearby places (restaurants, cafes, bars, pharmacies, etc.) using OpenStreetMap. | 读 Telegram 位置；其余是 OpenStreetMap 查询 |

### 工具使用

| 技能 | 作用 | 备注 |
| --- | --- | --- |
| `obsidian` | Read, search, create, and edit notes in the Obsidian vault. | 从 Hermes 复制；vault 路径读 `OBSIDIAN_VAULT_PATH` |
| `xurl` | X/Twitter via xurl CLI: raw post search, posting, DM, media. | 从 Hermes 复制；Docker/Hermes HOME 说明可忽略 |
| `himalaya` | Himalaya CLI: IMAP/SMTP email from terminal. | 从 Hermes 复制；含少量 Hermes gateway 说明 |

