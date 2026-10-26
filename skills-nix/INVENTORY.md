# 技能来源与阶段 4 迁移记录

记录 `skills-nix/` 当前每个技能的来源，以及 cc-switch SSOT
（`~/.config/cc-switch-tui/skills`）里 111 个技能的去向。分析的结论已经落地在仓库里，
本文是证据与决策记录。

## 1. 现状

部署面共 **68 个技能**，全部是扁平的 `<dest>/<name>/SKILL.md`：

| 来源 | 数量 | 说明 |
| --- | --- | --- |
| `addyosmani/agent-skills` | 21 | 上游布局就是 `skills/<name>`；20 个来自 SSOT，`debugging-and-error-recovery` 是额外启用的上游技能 |
| `MidAutumnMoon/TaysiTsuki` | 11 | `home/agents/skills`，本身就是单层 |
| `browser-act/skills` | 1 | `filter.nameRegex` 只取 `browser-act` |
| `local/` | 35 | 28 个从 SSOT 迁入、5 个从 Hermes toolkit 复制、2 个本仓库新写 |
| 合计 | 68 | |

目标目录共 4 个：`claude`、`codex`、`opencode`、`agents`
（`$HOME/.agents/skills`，dsh 的 user-agents root，所以 dsh 能看到全部 68 个）。
`gemini` 目标已移除。

为什么要扁平：dsh 的技能加载器（`@deepseek-ai/dsh-skill-filesystem` 的
`discoverRoot`）只列 skills 根目录的一层；带 `idPrefix` 或分类目录的布局对它是
不可见的。

## 2. 上游来源

| source | 仓库 | 锁定版本 | 布局 | 取用 | 数量 |
| --- | --- | --- | --- | --- | --- |
| `addyosmani` | `github:addyosmani/agent-skills` | `aeac41d` | `skills/<name>` | `enable` | 21 |
| `browser-act` | `github:browser-act/skills` | `11c057b` | 仓库根下 `browser-act/` | `filter.nameRegex` | 1 |
| `taysi` | `github:MidAutumnMoon/TaysiTsuki` | `9fa573c` | `home/agents/skills/<name>` | `enable` | 11 |
| `local` | 本仓库 | – | `local/<name>` | `enable` | 35 |

**Hermes 不是输入，也没有整套导入。** `NousResearch/hermes-agent` 是整个 agent
运行时（271 MB），与这里相关的 12 个技能分三类处理：

- 5 个与 agent 无关的工具/技术技能还留在 `local/`：`obsidian`、`mcporter`、
  `codebase-inspection`、`requesting-code-review`、`spike`；
- 3 个依赖 Hermes 自身工具/运行时的技能去掉：`claude-code`、`opencode`、
  `subagent-driven-development`（`delegate_task`）；
- `himalaya`、`xurl`、`python-debugpy`、`node-inspect-debugger` 曾复制进来，
  后来陆续删掉（后两个的 Hermes 专属章节占比过高）。

## 3. 判定方法

1. **枚举 SSOT**：递归查找含 `SKILL.md` 的目录，得到 111 个技能。
2. **启用面**：cc-switch 数据库 `skills` 表的 `enabled_claude` / `enabled_codex`。
3. **上游比对**：sha256 逐文件比对 + 词集合 Dice 相似度，候选仓库包括
   addyosmani/agent-skills、hermes-agent、obra/superpowers、anthropics/skills、
   browser-act/skills、TaysiTsuki、baoyu-skills、myclaude、awesome-claude-skills。
4. **口径**：先看上游；没有上游的看是否只对 Hermes 有意义；剩下的进 `local/`。

## 4. SSOT 111 项的处置

| 去向 | 数量 |
| --- | --- |
| addyosmani/agent-skills | 20 |
| TaysiTsuki | 8 |
| browser-act/skills | 1 |
| local/（沿用原副本） | 28 |
| local/（从 hermes-agent 复制，现剩 5 个） | 5 |
| 已移出 SSOT（6 个 `.bak` + 重复的嵌套 TDD） | 7 |
| 已删除（`singbox-config`、`codex`、`cc-switch-app-type-wiring`、`web-access`、`native-mcp`、`kanban-orchestrator`、`kanban-worker`、`webhook-subscriptions`、`xurl`、`himalaya`、`systematic-debugging`、`hdd-pending-sector-repair`、`python-debugpy`、`node-inspect-debugger`） | 14 |
| 不迁移（Hermes 专用 3 + Hermes 运行时技能 3） | 6 |
| 暂不迁移（macOS 专用 5、media 3、productivity 14） | 22 |
| 合计 | 111 |

### `api-and-interface-design/`

| 技能目录 | 现在来自 |
| --- | --- |
| `api-and-interface-design` | addyosmani/agent-skills |

### `apple/`

| 技能目录 | 现在来自 |
| --- | --- |
| `apple/apple-notes` | 暂不迁移 |
| `apple/apple-reminders` | 暂不迁移 |
| `apple/findmy` | 暂不迁移 |
| `apple/imessage` | 暂不迁移 |
| `apple/macos-computer-use` | 暂不迁移 |

### `autonomous-ai-agents/`

| 技能目录 | 现在来自 |
| --- | --- |
| `autonomous-ai-agents/claude-code` | 不迁移（Hermes 运行时技能） |
| `autonomous-ai-agents/codex` | 已删除 |
| `autonomous-ai-agents/codex.bak` | 已移出 SSOT |
| `autonomous-ai-agents/hermes-agent` | 不迁移（Hermes 专用） |
| `autonomous-ai-agents/opencode` | 不迁移（Hermes 运行时技能） |

### `awesome-cv-customization/`

| 技能目录 | 现在来自 |
| --- | --- |
| `awesome-cv-customization` | local/ |

### `browser-act/`

| 技能目录 | 现在来自 |
| --- | --- |
| `browser-act` | browser-act/skills |

### `browser-testing-with-devtools/`

| 技能目录 | 现在来自 |
| --- | --- |
| `browser-testing-with-devtools` | addyosmani/agent-skills |

### `ci-cd-and-automation/`

| 技能目录 | 现在来自 |
| --- | --- |
| `ci-cd-and-automation` | addyosmani/agent-skills |
| `ci-cd-and-automation/desktop-app-ci` | local/ |
| `ci-cd-and-automation/desktop-app-qt6-ci` | local/ |
| `ci-cd-and-automation/nix-flake-ci` | local/ |

### `code-review-and-quality/`

| 技能目录 | 现在来自 |
| --- | --- |
| `code-review-and-quality` | addyosmani/agent-skills |
| `code-review-and-quality/cpp-code-review` | local/ |

### `code-simplification/`

| 技能目录 | 现在来自 |
| --- | --- |
| `code-simplification` | addyosmani/agent-skills |

### `context-engineering/`

| 技能目录 | 现在来自 |
| --- | --- |
| `context-engineering` | addyosmani/agent-skills |

### `deprecation-and-migration/`

| 技能目录 | 现在来自 |
| --- | --- |
| `deprecation-and-migration` | addyosmani/agent-skills |

### `devops/`

| 技能目录 | 现在来自 |
| --- | --- |
| `devops/docker-compose-selfhost` | local/ |
| `devops/hdd-pending-sector-repair` | 已删除 |
| `devops/kanban-orchestrator` | 已删除 |
| `devops/kanban-orchestrator.bak` | 已移出 SSOT |
| `devops/kanban-worker` | 已删除 |
| `devops/kanban-worker.bak` | 已移出 SSOT |
| `devops/webhook-subscriptions` | 已删除 |

### `documentation-and-adrs/`

| 技能目录 | 现在来自 |
| --- | --- |
| `documentation-and-adrs` | addyosmani/agent-skills |

### `domain-name-brainstormer/`

| 技能目录 | 现在来自 |
| --- | --- |
| `domain-name-brainstormer` | local/ |

### `email/`

| 技能目录 | 现在来自 |
| --- | --- |
| `email/himalaya` | 已删除 |
| `email/himalaya.bak` | 已移出 SSOT |

### `frontend-ui-engineering/`

| 技能目录 | 现在来自 |
| --- | --- |
| `frontend-ui-engineering` | addyosmani/agent-skills |

### `git-workflow-and-versioning/`

| 技能目录 | 现在来自 |
| --- | --- |
| `git-workflow-and-versioning` | addyosmani/agent-skills |

### `github/`

| 技能目录 | 现在来自 |
| --- | --- |
| `github/codebase-inspection` | local/（从 hermes-agent 复制） |
| `github/github-auth` | local/ |
| `github/github-auth.bak` | 已移出 SSOT |
| `github/github-code-review` | local/ |
| `github/github-issues` | local/ |
| `github/github-pr-workflow` | local/ |
| `github/github-release-management` | local/ |
| `github/github-repo-management` | local/ |

### `idea-refine/`

| 技能目录 | 现在来自 |
| --- | --- |
| `idea-refine` | addyosmani/agent-skills |

### `incremental-implementation/`

| 技能目录 | 现在来自 |
| --- | --- |
| `incremental-implementation` | addyosmani/agent-skills |

### `leisure/`

| 技能目录 | 现在来自 |
| --- | --- |
| `leisure/find-nearby` | local/ |

### `mcp/`

| 技能目录 | 现在来自 |
| --- | --- |
| `mcp/mcporter` | local/（从 hermes-agent 复制） |
| `mcp/native-mcp` | 已删除 |

### `media/`

| 技能目录 | 现在来自 |
| --- | --- |
| `media/gif-search` | 暂不迁移 |
| `media/heartmula` | 暂不迁移 |
| `media/songsee` | 暂不迁移 |

### `nix-flake-development/`

| 技能目录 | 现在来自 |
| --- | --- |
| `nix-flake-development` | local/ |

### `nix-module-capability-detection/`

| 技能目录 | 现在来自 |
| --- | --- |
| `nix-module-capability-detection` | local/ |

### `note-taking/`

| 技能目录 | 现在来自 |
| --- | --- |
| `note-taking/obsidian` | local/（从 hermes-agent 复制） |
| `note-taking/obsidian.bak` | 已移出 SSOT |

### `performance-optimization/`

| 技能目录 | 现在来自 |
| --- | --- |
| `performance-optimization` | addyosmani/agent-skills |

### `planning-and-task-breakdown/`

| 技能目录 | 现在来自 |
| --- | --- |
| `planning-and-task-breakdown` | addyosmani/agent-skills |

### `productivity/`

| 技能目录 | 现在来自 |
| --- | --- |
| `productivity/box` | 暂不迁移 |
| `productivity/document-to-action-items` | 暂不迁移 |
| `productivity/docx` | 暂不迁移 |
| `productivity/maps` | 暂不迁移 |
| `productivity/meeting-action-items` | 暂不迁移 |
| `productivity/nano-pdf` | 暂不迁移 |
| `productivity/notion` | 暂不迁移 |
| `productivity/pdf` | 暂不迁移 |
| `productivity/petdex` | 暂不迁移 |
| `productivity/product-price-monitor` | 暂不迁移 |
| `productivity/session-librarian` | 暂不迁移 |
| `productivity/teams-meeting-pipeline` | 暂不迁移 |
| `productivity/weekly-review-planning` | 暂不迁移 |
| `productivity/xlsx` | 暂不迁移 |

### `release-skills/`

| 技能目录 | 现在来自 |
| --- | --- |
| `release-skills` | local/ |

### `security-and-hardening/`

| 技能目录 | 现在来自 |
| --- | --- |
| `security-and-hardening` | addyosmani/agent-skills |

### `shell-scripting/`

| 技能目录 | 现在来自 |
| --- | --- |
| `shell-scripting` | local/ |

### `shipping-and-launch/`

| 技能目录 | 现在来自 |
| --- | --- |
| `shipping-and-launch` | addyosmani/agent-skills |

### `singbox-config/`

| 技能目录 | 现在来自 |
| --- | --- |
| `singbox-config` | 已删除 |

### `social-media/`

| 技能目录 | 现在来自 |
| --- | --- |
| `social-media/xurl` | 已删除 |

### `software-development/`

| 技能目录 | 现在来自 |
| --- | --- |
| `software-development/adding-rust-enum-variant` | local/ |
| `software-development/c-development` | local/ |
| `software-development/cargo-dependency-update` | local/ |
| `software-development/cc-switch-app-type-wiring` | 已删除 |
| `software-development/debugging-hermes-tui-commands` | 不迁移（Hermes 专用） |
| `software-development/design-md-init` | local/ |
| `software-development/hermes-agent-skill-authoring` | 不迁移（Hermes 专用） |
| `software-development/node-inspect-debugger` | 已删除 |
| `software-development/project-docs` | local/ |
| `software-development/python-debugpy` | 已删除 |
| `software-development/requesting-code-review` | local/（从 hermes-agent 复制） |
| `software-development/rust-pre-commit-hook` | local/ |
| `software-development/rust-struct-field-propagation` | local/ |
| `software-development/rust-test-isolation` | local/ |
| `software-development/spike` | local/（从 hermes-agent 复制） |
| `software-development/subagent-driven-development` | 不迁移（Hermes 运行时技能） |
| `software-development/systematic-debugging` | 已删除 |
| `software-development/test-driven-development` | 已移出 SSOT |
| `software-development/writing-plans` | local/ |

### `source-driven-development/`

| 技能目录 | 现在来自 |
| --- | --- |
| `source-driven-development` | addyosmani/agent-skills |

### `spec-driven-development/`

| 技能目录 | 现在来自 |
| --- | --- |
| `spec-driven-development` | addyosmani/agent-skills |

### `taysi/`

| 技能目录 | 现在来自 |
| --- | --- |
| `taysi/chinese-prose-lint` | TaysiTsuki |
| `taysi/code-cultivation` | TaysiTsuki |
| `taysi/group-meeting` | TaysiTsuki |
| `taysi/handoff` | TaysiTsuki |
| `taysi/host-system-convention` | TaysiTsuki |
| `taysi/humanizer` | TaysiTsuki |
| `taysi/prune-comments-and-docs` | TaysiTsuki |
| `taysi/sillytavern-card-backup` | TaysiTsuki |

### `test-driven-development/`

| 技能目录 | 现在来自 |
| --- | --- |
| `test-driven-development` | addyosmani/agent-skills |

### `using-agent-skills/`

| 技能目录 | 现在来自 |
| --- | --- |
| `using-agent-skills` | addyosmani/agent-skills |

### `web-access/`

| 技能目录 | 现在来自 |
| --- | --- |
| `web-access` | 已删除 |

### `workflow-skill-architect/`

| 技能目录 | 现在来自 |
| --- | --- |
| `workflow-skill-architect` | local/ |


## 5. 待确认

1. `apple/*` 与 `macos-computer-use` 只在 handyMini 有意义，是否要在下一轮启用？
2. `media/*` 与 `productivity/*` 的上游就是 hermes-agent；需要时从上游取一两个文件
   放进 `local/` 即可，不必为此引入 271 MB 的输入。
3. TaysiTsuki 里还有 4 个未启用的技能（`grill-me`、`grilling`、
   `language-style-guide`、`wait-what`），目前判断是重复或过薄，先留着不启用。
