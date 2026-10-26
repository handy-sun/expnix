# 阶段 4 迁移清单：cc-switch SSOT 到 skills-nix

对 `~/.config/cc-switch-tui/skills/` 下 111 个技能逐项分类，并记录本轮实际执行的
结果。本文档是迁移的决策记录：清单结论已经是仓库现状，不再是待办建议。

## 1. 结论汇总

| 结论 | 数量 | 说明 |
| --- | --- | --- |
| 进 `local/` | 70 | 已复制进 `skills-nix/local/` 并在 `catalog.nix` 登记 |
| 改用 taysi 源 | 8 | 由 `TaysiTsuki` flake source 提供，不再复制 |
| 暂不迁移 | 23 | 未在 claude/codex 启用，或仅 macOS 有意义 |
| 不迁移 | 10 | `.bak`、重复副本、Hermes 运行时专用 |
| 合计 | 111 | |

部署面：`local/` 72 个（本轮 70 + 原有 2），`taysi/` 8 个，合计 80 个 skill ID。

## 2. 判定方法

1. **枚举**：递归查找含 `SKILL.md` 的目录，得到 111 个技能；另有 6 个目录不含
   `SKILL.md`（见 §5）。
2. **现状启用面**：cc-switch 数据库 `skills` 表 48 行，用 `enabled_claude` 与
   `enabled_codex` 判断这个技能当时是否真的被那两个 agent 使用。Hermes 的启用面
   不参与决策，因为第一阶段不接管 Hermes。
3. **上游核对**：把每个 `SKILL.md` 的 sha256 与下列仓库逐文件比对，另用词集合
   Dice 相似度找同名技能的最近版本（0–1）：
   - `NousResearch/hermes-agent` @ `749cb638`：`skills/`（198 个）与
     `optional-skills/`（13 个）
   - `obra/superpowers` @ `2ce8aa1`（15）
   - `anthropics/skills` @ `dbd4588`（20）
   - `JimLiu/baoyu-skills` @ `1567581`（22）、`cexll/myclaude` @ `f2e75c1`（11）、
     `ComposioHQ/awesome-claude-skills` @ `be2a406`（864）
4. **口径**：sha 相同或相似度 ≥ 0.9 且同名 → 上游一致；相似度 < 0.9 → 本地有差异。
   相似度只能判断是否同源，不能替代人工阅读。

## 3. 本轮不 pin 上游

与 `NousResearch/hermes-agent` 一致的 13 个技能本来可以用两个 registry manifest
（`subdir = "skills"` 与 `optional-skills`）一次 pin 进来，但 hermes-agent 工作树
366MB（含 assets、web、ui-tui），而本轮只需要其中 13 个。决定是**先复制进
`local/`**，不引入该 pin：

- 优点：仓库自包含、体积可控、不需要拉整个上游；
- 代价：这 13 个不再跟随上游更新，需要手工同步；
- 保留的余地：以后如果 Hermes 端的 `productivity/*`、`media/*` 也要用，再按
  §2 的方法加 manifest，把 `local/` 里的同名副本删掉即可。

## 4. 清单

### `api-and-interface-design/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `api-and-interface-design` | 进 local/ | 无上游对应，本地维护 |

### `apple/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `apple/apple-notes` | 暂不迁移 | 仅 macOS（handyMini），需要时再单独放行 |
| `apple/apple-reminders` | 暂不迁移 | 仅 macOS（handyMini），需要时再单独放行 |
| `apple/findmy` | 暂不迁移 | 仅 macOS（handyMini），需要时再单独放行 |
| `apple/imessage` | 暂不迁移 | 仅 macOS（handyMini），需要时再单独放行 |
| `apple/macos-computer-use` | 暂不迁移 | 仅 macOS（handyMini），需要时再单独放行 |

### `autonomous-ai-agents/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `autonomous-ai-agents/claude-code` | 进 local/ | 与上游一致（`skills/autonomous-ai-agents/claude-code`），本轮先复制进 `local/`，不 pin |
| `autonomous-ai-agents/codex` | 进 local/ | 作者标记为 Hermes，但上游无对应技能（相似度 0.85） |
| `autonomous-ai-agents/codex.bak` | 不迁移 | `.bak` 备份目录，已移出 SSOT |
| `autonomous-ai-agents/hermes-agent` | 不迁移 | Hermes 运行时专用 |
| `autonomous-ai-agents/opencode` | 进 local/ | 与上游一致（`skills/autonomous-ai-agents/opencode`），本轮先复制进 `local/`，不 pin |

### `awesome-cv-customization/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `awesome-cv-customization` | 进 local/ | 无上游对应，本地维护 |

### `browser-act/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `browser-act` | 暂不迁移 | 未在任何 agent 启用；来源 `github.com/browser-act/skills` 未验证 |

### `browser-testing-with-devtools/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `browser-testing-with-devtools` | 进 local/ | 无上游对应，本地维护 |

### `ci-cd-and-automation/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `ci-cd-and-automation` | 进 local/ | 无上游对应，本地维护 |
| `ci-cd-and-automation/desktop-app-ci` | 进 local/ | 无上游对应，本地维护 |
| `ci-cd-and-automation/desktop-app-qt6-ci` | 进 local/ | 无上游对应，本地维护 |
| `ci-cd-and-automation/nix-flake-ci` | 进 local/ | 无上游对应，本地维护 |

### `code-review-and-quality/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `code-review-and-quality` | 进 local/ | 无上游对应，本地维护 |
| `code-review-and-quality/cpp-code-review` | 进 local/ | 无上游对应，本地维护 |

### `code-simplification/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `code-simplification` | 进 local/ | 无上游对应，本地维护 |

### `context-engineering/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `context-engineering` | 进 local/ | 无上游对应，本地维护 |

### `deprecation-and-migration/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `deprecation-and-migration` | 进 local/ | 无上游对应，本地维护 |

### `devops/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `devops/docker-compose-selfhost` | 进 local/ | 无上游对应，本地维护 |
| `devops/hdd-pending-sector-repair` | 进 local/ | 无上游对应，本地维护 |
| `devops/kanban-orchestrator` | 进 local/ | 无上游对应，本地维护 |
| `devops/kanban-orchestrator.bak` | 不迁移 | `.bak` 备份目录，已移出 SSOT |
| `devops/kanban-worker` | 进 local/ | 无上游对应，本地维护 |
| `devops/kanban-worker.bak` | 不迁移 | `.bak` 备份目录，已移出 SSOT |
| `devops/webhook-subscriptions` | 进 local/ | 无上游对应，本地维护 |

### `documentation-and-adrs/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `documentation-and-adrs` | 进 local/ | 无上游对应，本地维护 |

### `domain-name-brainstormer/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `domain-name-brainstormer` | 进 local/ | 无上游对应，本地维护 |

### `email/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `email/himalaya` | 进 local/ | 与上游一致（`skills/email/himalaya`），本轮先复制进 `local/`，不 pin |
| `email/himalaya.bak` | 不迁移 | `.bak` 备份目录，已移出 SSOT |

### `frontend-ui-engineering/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `frontend-ui-engineering` | 进 local/ | 无上游对应，本地维护 |

### `git-workflow-and-versioning/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `git-workflow-and-versioning` | 进 local/ | 无上游对应，本地维护 |

### `github/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `github/codebase-inspection` | 进 local/ | 与上游一致（`skills/software-development/codebase-inspection`），本轮先复制进 `local/`，不 pin |
| `github/github-auth` | 进 local/ | 作者标记为 Hermes，但上游无对应技能（相似度 0.26） |
| `github/github-auth.bak` | 不迁移 | `.bak` 备份目录，已移出 SSOT |
| `github/github-code-review` | 进 local/ | 作者标记为 Hermes，但上游无对应技能（相似度 0.32） |
| `github/github-issues` | 进 local/ | 作者标记为 Hermes，但上游无对应技能（相似度 0.22） |
| `github/github-pr-workflow` | 进 local/ | 作者标记为 Hermes，但上游无对应技能（相似度 0.28） |
| `github/github-release-management` | 进 local/ | 无上游对应，本地维护 |
| `github/github-repo-management` | 进 local/ | 作者标记为 Hermes，但上游无对应技能（相似度 0.24） |

### `idea-refine/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `idea-refine` | 进 local/ | 无上游对应，本地维护 |

### `incremental-implementation/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `incremental-implementation` | 进 local/ | 无上游对应，本地维护 |

### `leisure/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `leisure/find-nearby` | 进 local/ | 无上游对应，本地维护 |

### `mcp/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `mcp/mcporter` | 进 local/ | 与上游一致（`optional-skills/mcp/mcporter`），本轮先复制进 `local/`，不 pin |
| `mcp/native-mcp` | 进 local/ | 作者标记为 Hermes，但上游无对应技能（相似度 0.3） |

### `media/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `media/gif-search` | 暂不迁移 | 上游一致（`skills/media/gif-search`），当前未在 claude/codex 启用 |
| `media/heartmula` | 暂不迁移 | 上游一致（`optional-skills/creative/heartmula`），当前未在 claude/codex 启用 |
| `media/songsee` | 暂不迁移 | 上游一致（`skills/media/songsee`），当前未在 claude/codex 启用 |

### `nix-flake-development/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `nix-flake-development` | 进 local/ | 无上游对应，本地维护 |

### `nix-module-capability-detection/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `nix-module-capability-detection` | 进 local/ | 无上游对应，本地维护 |

### `note-taking/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `note-taking/obsidian` | 进 local/ | 与上游一致（`skills/note-taking/obsidian`），本轮先复制进 `local/`，不 pin |
| `note-taking/obsidian.bak` | 不迁移 | `.bak` 备份目录，已移出 SSOT |

### `performance-optimization/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `performance-optimization` | 进 local/ | 无上游对应，本地维护 |

### `planning-and-task-breakdown/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `planning-and-task-breakdown` | 进 local/ | 无上游对应，本地维护 |

### `productivity/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `productivity/box` | 暂不迁移 | 上游一致（`skills/productivity/box`），当前未在 claude/codex 启用 |
| `productivity/document-to-action-items` | 暂不迁移 | 上游一致（`skills/productivity/document-to-action-items`），当前未在 claude/codex 启用 |
| `productivity/docx` | 暂不迁移 | 上游一致（`skills/productivity/docx`），当前未在 claude/codex 启用 |
| `productivity/maps` | 暂不迁移 | 上游一致（`skills/productivity/maps`），当前未在 claude/codex 启用 |
| `productivity/meeting-action-items` | 暂不迁移 | 上游一致（`skills/productivity/meeting-action-items`），当前未在 claude/codex 启用 |
| `productivity/nano-pdf` | 暂不迁移 | 未在 claude/codex 启用，且上游无对应 |
| `productivity/notion` | 暂不迁移 | 上游一致（`skills/productivity/notion`），当前未在 claude/codex 启用 |
| `productivity/pdf` | 暂不迁移 | 上游一致（`skills/productivity/pdf`），当前未在 claude/codex 启用 |
| `productivity/petdex` | 暂不迁移 | 未在 claude/codex 启用，且上游无对应 |
| `productivity/product-price-monitor` | 暂不迁移 | 上游一致（`skills/productivity/product-price-monitor`），当前未在 claude/codex 启用 |
| `productivity/session-librarian` | 暂不迁移 | 未在 claude/codex 启用，且上游无对应 |
| `productivity/teams-meeting-pipeline` | 暂不迁移 | 上游一致（`skills/productivity/teams-meeting-pipeline`），当前未在 claude/codex 启用 |
| `productivity/weekly-review-planning` | 暂不迁移 | 上游一致（`skills/productivity/weekly-review-planning`），当前未在 claude/codex 启用 |
| `productivity/xlsx` | 暂不迁移 | 上游一致（`skills/productivity/xlsx`），当前未在 claude/codex 启用 |

### `release-skills/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `release-skills` | 进 local/ | 无上游对应，本地维护 |

### `security-and-hardening/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `security-and-hardening` | 进 local/ | 无上游对应，本地维护 |

### `shell-scripting/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `shell-scripting` | 进 local/ | 无上游对应，本地维护 |

### `shipping-and-launch/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `shipping-and-launch` | 进 local/ | 无上游对应，本地维护 |

### `singbox-config/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `singbox-config` | 进 local/ | 无上游对应，本地维护 |

### `social-media/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `social-media/xurl` | 进 local/ | 与上游一致（`skills/social-media/xurl`），本轮先复制进 `local/`，不 pin |

### `software-development/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `software-development/adding-rust-enum-variant` | 进 local/ | 无上游对应，本地维护 |
| `software-development/c-development` | 进 local/ | 无上游对应，本地维护 |
| `software-development/cargo-dependency-update` | 进 local/ | 无上游对应，本地维护 |
| `software-development/cc-switch-app-type-wiring` | 进 local/ | 无上游对应，本地维护 |
| `software-development/debugging-hermes-tui-commands` | 不迁移 | Hermes 运行时专用 |
| `software-development/design-md-init` | 进 local/ | 无上游对应，本地维护 |
| `software-development/hermes-agent-skill-authoring` | 不迁移 | Hermes 运行时专用 |
| `software-development/node-inspect-debugger` | 进 local/ | 与上游一致（`skills/software-development/node-inspect-debugger`），本轮先复制进 `local/`，不 pin |
| `software-development/project-docs` | 进 local/ | 无上游对应，本地维护 |
| `software-development/python-debugpy` | 进 local/ | 与上游一致（`skills/software-development/python-debugpy`），本轮先复制进 `local/`，不 pin |
| `software-development/requesting-code-review` | 进 local/ | 与上游一致（`skills/software-development/requesting-code-review`），本轮先复制进 `local/`，不 pin |
| `software-development/rust-pre-commit-hook` | 进 local/ | 无上游对应，本地维护 |
| `software-development/rust-struct-field-propagation` | 进 local/ | 无上游对应，本地维护 |
| `software-development/rust-test-isolation` | 进 local/ | 无上游对应，本地维护 |
| `software-development/spike` | 进 local/ | 与上游一致（`skills/software-development/spike`），本轮先复制进 `local/`，不 pin |
| `software-development/subagent-driven-development` | 进 local/ | 与上游一致（`optional-skills/software-development/subagent-driven-development`），本轮先复制进 `local/`，不 pin |
| `software-development/systematic-debugging` | 进 local/ | Hermes 改编版（obra/superpowers），已大幅改写（相似度 0.78） |
| `software-development/test-driven-development` | 不迁移 | 与顶层 `test-driven-development` 重复，已移出 SSOT |
| `software-development/writing-plans` | 进 local/ | Hermes 改编版（obra/superpowers），已大幅改写（相似度 0.39） |

### `source-driven-development/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `source-driven-development` | 进 local/ | 无上游对应，本地维护 |

### `spec-driven-development/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `spec-driven-development` | 进 local/ | 无上游对应，本地维护 |

### `taysi/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `taysi/chinese-prose-lint` | 改用 taysi 源 | TaysiTsuki 的 `home/agents/skills/` 是 source of truth，已作为 flake source 引入 |
| `taysi/code-cultivation` | 改用 taysi 源 | TaysiTsuki 的 `home/agents/skills/` 是 source of truth，已作为 flake source 引入 |
| `taysi/group-meeting` | 改用 taysi 源 | TaysiTsuki 的 `home/agents/skills/` 是 source of truth，已作为 flake source 引入 |
| `taysi/handoff` | 改用 taysi 源 | TaysiTsuki 的 `home/agents/skills/` 是 source of truth，已作为 flake source 引入 |
| `taysi/host-system-convention` | 改用 taysi 源 | TaysiTsuki 的 `home/agents/skills/` 是 source of truth，已作为 flake source 引入 |
| `taysi/humanizer` | 改用 taysi 源 | TaysiTsuki 的 `home/agents/skills/` 是 source of truth，已作为 flake source 引入 |
| `taysi/prune-comments-and-docs` | 改用 taysi 源 | TaysiTsuki 的 `home/agents/skills/` 是 source of truth，已作为 flake source 引入 |
| `taysi/sillytavern-card-backup` | 改用 taysi 源 | TaysiTsuki 的 `home/agents/skills/` 是 source of truth，已作为 flake source 引入 |

### `test-driven-development/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `test-driven-development` | 进 local/ | 无上游对应，本地维护 |

### `using-agent-skills/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `using-agent-skills` | 进 local/ | 无上游对应，本地维护 |

### `web-access/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `web-access` | 进 local/ | 无上游对应，本地维护 |

### `workflow-skill-architect/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `workflow-skill-architect` | 进 local/ | 无上游对应，本地维护 |

## 5. 不含 `SKILL.md` 的目录

agent-skills 只发现含 `SKILL.md` 的目录，以下内容不会被同步，也不进入清单：

| 目录 | 内容 | 处理 |
| --- | --- | --- |
| `diagramming/` `domain/` `feeds/` `gifs/` `inference-sh/` | 只有 `DESCRIPTION.md`，没有技能 | 忽略，可随 SSOT 一起归档 |
| `ui-ux-pro-max/` | 整个仓库检出（`skill.json`、`src/`、`cli/`、screenshots） | 需要时按上游 pin（Next Level Builder），不要复制进 `local/` |

## 6. 已执行的迁移

一个提交完成，原来计划的四个批次合并执行：

1. 复制 70 个技能到 `skills-nix/local/`，保留原来的分类层级；
2. 把 `ci-cd-and-automation` 与 `code-review-and-quality` 两个"目录内自带
   SKILL.md 又有子技能"的父级技能拆到 `<name>-overview/`：bundle 把技能物化成
   指向技能目录的软链，父级与子级不能共用同一个路径；
3. `catalog.nix` 增加 `sources.taysi`（`TaysiTsuki` 的
   `home/agents/skills`）并启用 8 个 taysi 技能；
4. 接管时把 15 个目录移出 SSOT（备份在
   `~/backups/skills-nix-takeover-20261026-135340/pruned`）：6 个 `.bak`、被
   顶层版本取代的 `software-development/test-driven-development`、`taysi/` 的
   8 个副本。SSOT 从 111 个技能降到 96 个。

验证：`just skills-check`、`nix build ./skills-nix`（80 个技能）、
`CODEX_HOME=/tmp/fakecodex-80 codex debug prompt-input`（发现 80 个技能，含
二级目录与 taysi）；接管后真实目录见 `MIGRATION.md` §3、§4。

## 7. 仍然待确认

1. `apple/*` 与 `macos-computer-use` 只在 handyMini 有意义，是否要在下一轮启用？
2. `browser-act` 与 `productivity/{nano-pdf,petdex,session-librarian}` 上游不明，
   弃用还是保留？
3. 迁移进来的 70 个里可能还有不再使用的（例如 `devops/hdd-pending-sector-repair`
   这类一次性排障技能），是否需要再精简一轮？
4. 13 个与 hermes 上游一致的技能改为手工维护后，多久同步一次？
