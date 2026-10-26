# 技能来源与阶段 4 迁移记录

记录 `skills-nix/` 当前每个技能的来源，以及 cc-switch SSOT（`~/.config/cc-switch-tui/skills`）
里 111 个技能的去向。只读分析的结论已经在仓库里落地，本文是它的证据与决策记录。

## 1. 现状

部署面共 **81 个技能**，全部是扁平的 `<dest>/<name>/SKILL.md`：

| 来源 | 数量 | 说明 |
| --- | --- | --- |
| `addyosmani/agent-skills` | 20 | 上游布局就是 `skills/<name>`，直接 `enable` |
| `NousResearch/hermes-agent` | 12 | 上游是 `skills/<category>/<name>`，用 `skills.explicit` 改名压平 |
| `MidAutumnMoon/TaysiTsuki` | 8 | `home/agents/skills`，本身就是单层 |
| `browser-act/skills` | 1 | 用 `filter.nameRegex` 只取 `browser-act` |
| 本仓库 `local/` | 40 | 38 个从 SSOT 迁移 + 2 个本仓库新写（`skills-nix-maintenance`、`expnix-workflow`） |
| 合计 | 81 | |

为什么要扁平：DSH 的技能加载器（`@deepseek-ai/dsh-skill-filesystem` 的
`discoverRoot`）只列 skills 根目录的一层，`<root>/<name>/SKILL.md` 之外的内容
不会被发现；`~/.agents/skills` 也是同样的扫描方式。带 `idPrefix` 或分类目录的
布局对这些 agent 完全不可见。

## 2. 上游来源

| source | 仓库 | 锁定版本 | 体积 | 布局 | 取用 |
| --- | --- | --- | --- | --- | --- |
| `addyosmani` | `github:addyosmani/agent-skills` | `aeac41d` | 1.6 MB | `skills/<name>` | `enable` |
| `hermes` | `github:NousResearch/hermes-agent` | `df5dbc2` | 271 MB | `skills/<category>/<name>` | `explicit` 改名 |
| `hermes-optional` | 同上 | `df5dbc2` | – | `optional-skills/<category>/<name>` | `explicit` 改名 |
| `browser-act` | `github:browser-act/skills` | `11c057b` | 3.6 MB | 仓库根下 `browser-act/` | `filter.nameRegex` |
| `taysi` | `github:MidAutumnMoon/TaysiTsuki` | `9fa573c` | 2.7 MB | `home/agents/skills/<name>` | `enable` |
| `local` | 本仓库 | – | – | `local/<name>` | `enable` |

`hermes-agent` 是整个 agent 运行时仓库，只为 12 个技能引入；如果体积不可接受，
把这 12 个复制回 `local/` 就能去掉该输入。

## 3. 判定方法

1. **枚举 SSOT**：递归查找含 `SKILL.md` 的目录，得到 111 个技能。
2. **启用面**：cc-switch 数据库 `skills` 表的 `enabled_claude` / `enabled_codex`，
   判断当时是否真的被那两个 agent 使用。
3. **上游比对**：把每个 `SKILL.md` 的 sha256 与下列仓库逐文件比对，并用词集合
   Dice 相似度找同名技能最近版本：hermes-agent、addyosmani/agent-skills、
   obra/superpowers、anthropics/skills、browser-act/skills、TaysiTsuki、
   JimLiu/baoyu-skills、cexll/myclaude、ComposioHQ/awesome-claude-skills。
4. **口径**：上游有对应技能就引用上游（即使本地副本有轻微改动，以上游为准）；
   没有上游的项目专用技能留在 `local/`；只有 Hermes 自己使用或仅 macOS 有意义的
   保持不动。

## 4. SSOT 111 项的处置

| 去向 | 数量 |
| --- | --- |
| addyosmani/agent-skills | 20 |
| hermes-agent | 12 |
| TaysiTsuki | 8 |
| browser-act/skills | 1 |
| local/ | 38 |
| 已移出 SSOT（6 个 `.bak` + 重复的嵌套 TDD） | 7 |
| 不迁移（Hermes 运行时专用） | 3 |
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
| `autonomous-ai-agents/claude-code` | hermes-agent |
| `autonomous-ai-agents/codex` | local/ |
| `autonomous-ai-agents/codex.bak` | 已移出 SSOT |
| `autonomous-ai-agents/hermes-agent` | 不迁移（Hermes 专用） |
| `autonomous-ai-agents/opencode` | hermes-agent |

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
| `devops/hdd-pending-sector-repair` | local/ |
| `devops/kanban-orchestrator` | local/ |
| `devops/kanban-orchestrator.bak` | 已移出 SSOT |
| `devops/kanban-worker` | local/ |
| `devops/kanban-worker.bak` | 已移出 SSOT |
| `devops/webhook-subscriptions` | local/ |

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
| `email/himalaya` | hermes-agent |
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
| `github/codebase-inspection` | hermes-agent |
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
| `mcp/mcporter` | hermes-agent |
| `mcp/native-mcp` | local/ |

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
| `note-taking/obsidian` | hermes-agent |
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
| `singbox-config` | local/ |

### `social-media/`

| 技能目录 | 现在来自 |
| --- | --- |
| `social-media/xurl` | hermes-agent |

### `software-development/`

| 技能目录 | 现在来自 |
| --- | --- |
| `software-development/adding-rust-enum-variant` | local/ |
| `software-development/c-development` | local/ |
| `software-development/cargo-dependency-update` | local/ |
| `software-development/cc-switch-app-type-wiring` | local/ |
| `software-development/debugging-hermes-tui-commands` | 不迁移（Hermes 专用） |
| `software-development/design-md-init` | local/ |
| `software-development/hermes-agent-skill-authoring` | 不迁移（Hermes 专用） |
| `software-development/node-inspect-debugger` | hermes-agent |
| `software-development/project-docs` | local/ |
| `software-development/python-debugpy` | hermes-agent |
| `software-development/requesting-code-review` | hermes-agent |
| `software-development/rust-pre-commit-hook` | local/ |
| `software-development/rust-struct-field-propagation` | local/ |
| `software-development/rust-test-isolation` | local/ |
| `software-development/spike` | hermes-agent |
| `software-development/subagent-driven-development` | hermes-agent |
| `software-development/systematic-debugging` | local/ |
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
| `web-access` | local/ |

### `workflow-skill-architect/`

| 技能目录 | 现在来自 |
| --- | --- |
| `workflow-skill-architect` | local/ |


## 5. 待确认

1. `apple/*` 与 `macos-computer-use` 只在 handyMini 有意义，是否要在下一轮启用？
2. `media/*` 与 `productivity/*` 上游就是 hermes-agent；需要时加进
   `skills.explicit` 即可，不必复制。
3. `local/` 的 40 个里可能还有不再使用的（例如 `hdd-pending-sector-repair` 这类
   一次性排障技能），是否需要再精简？
4. `browser-act` 技能依赖 uv 安装的 `browser-act` 包；包升级后需要重新核对
   SKILL.md 里的 CLI 用法。
