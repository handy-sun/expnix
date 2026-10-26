# 阶段 4 迁移清单：cc-switch SSOT 到 skills-nix

对 `~/.config/cc-switch-tui/skills/` 下 111 个技能逐项分类，给出「进
`skills-nix/local/`」「改用上游 source」「不迁移」三种结论。本文只记录分析结果，
不修改任何目录。

## 1. 结论汇总

| 结论 | 数量 | 含义 |
| --- | --- | --- |
| 进 `local/` | 57 | 本仓库自维护，无可用上游；按批次复制进 `skills-nix/local/` 并登记到 `catalog.nix` |
| 改上游 source | 13 | 与 `NousResearch/hermes-agent` 上游一致，改为 pin 上游，不在 `local/` 留副本 |
| 暂不迁移 | 23 | 当前未在 claude/codex 启用，或仅 macOS 有意义；pin 之后随时可启用 |
| 不迁移 | 17 | `.bak` 备份、TaysiTsuki 管理的副本、Hermes 运行时专用 |
| 待定 | 1 | 两个 `test-driven-development` 并存，需要二选一 |
| 合计 | 111 | |

## 2. 判定方法

1. **枚举**：递归查找含 `SKILL.md` 的目录，得到 111 个技能；另有 6 个目录不含
   `SKILL.md`（见 §5）。
2. **现状启用面**：cc-switch 数据库 `skills` 表 48 行，用 `enabled_claude` 与
   `enabled_codex` 判断这个技能现在是否真的被那两个 agent 使用。Hermes 的启用面
   不参与决策，因为第一阶段不接管 Hermes。
3. **上游核对**：把每个 `SKILL.md` 的 sha256 与下列仓库逐文件比对，另用词集合
   Dice 相似度找同名技能的最近版本（0–1）：
   - `NousResearch/hermes-agent` @ `749cb638`：`skills/`（198 个）与
     `optional-skills/`（13 个）
   - `obra/superpowers` @ `2ce8aa1`（15）
   - `anthropics/skills` @ `dbd4588`（20）
   - `JimLiu/baoyu-skills` @ `1567581`（22）、`cexll/myclaude` @ `f2e75c1`（11）、
     `ComposioHQ/awesome-claude-skills` @ `be2a406`（864）
4. **口径**：sha 相同或相似度 ≥ 0.9 且同名 → 视为上游一致；相似度 < 0.9 → 本地有
   差异，按自维护处理。相似度只能判断是否同源，不能替代人工阅读。

## 3. 上游 pin 方案

上游一致的部分来自 Hermes 的技能包，可以只 pin 一次：

```nix
# skills-nix/registry/sources/hermes.nix
{
  pin = {
    type = "github";
    owner = "NousResearch";
    repo = "hermes-agent";
    branch = "main";
  };

  subdir = "skills";
  idPrefix = "hermes";
  filter.maxDepth = 2;
}

# skills-nix/registry/sources/hermes-optional.nix
{
  pin = {
    type = "github";
    owner = "NousResearch";
    repo = "hermes-agent";
    branch = "main";
  };

  subdir = "optional-skills";
  idPrefix = "hermes-optional";
  filter.maxDepth = 2;
}
```

两个 manifest 是因为 `subdir` 不同；生成的 ID 形如
`hermes/software-development/test-driven-development`、
`hermes-optional/mcp/mcporter`。Hermes 端的 `productivity/*`、`media/*` 也来自
同一份 pin，需要时直接启用，不必复制。

**成本提示**：hermes-agent 工作树 366MB（含 assets、web、ui-tui），pin 会把整仓
拉进 store。如果只为这 13 个技能，把成本换成「复制进 `local/`、不跟随上游」也
是合理选择（见 §7 第 3 条）。

## 4. 清单

### `api-and-interface-design/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `api-and-interface-design` | 进 `local/` | 无上游对应，本地维护 |

### `apple/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `apple/apple-notes` | 暂不迁移 | 仅 macOS（handyMini），需要时再用 `agents` 单独放行 |
| `apple/apple-reminders` | 暂不迁移 | 仅 macOS（handyMini），需要时再用 `agents` 单独放行 |
| `apple/findmy` | 暂不迁移 | 仅 macOS（handyMini），需要时再用 `agents` 单独放行 |
| `apple/imessage` | 暂不迁移 | 仅 macOS（handyMini），需要时再用 `agents` 单独放行 |
| `apple/macos-computer-use` | 暂不迁移 | 仅 macOS（handyMini），需要时再用 `agents` 单独放行 |

### `autonomous-ai-agents/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `autonomous-ai-agents/claude-code` | 改上游 (`hermes/autonomous-ai-agents/claude-code`) | 上游同名技能相似度 0.98 |
| `autonomous-ai-agents/codex` | 进 `local/` | Hermes 改编版，与上游有差异（相似度 0.85） |
| `autonomous-ai-agents/codex.bak` | 不迁移 | `.bak` 备份目录，与主技能同源 |
| `autonomous-ai-agents/hermes-agent` | 不迁移 | Hermes 运行时专用 |
| `autonomous-ai-agents/opencode` | 改上游 (`hermes/autonomous-ai-agents/opencode`) | 上游同名技能相似度 1 |

### `awesome-cv-customization/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `awesome-cv-customization` | 进 `local/` | 无上游对应，本地维护 |

### `browser-act/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `browser-act` | 暂不迁移 | 未在任何 agent 启用；来源 `github.com/browser-act/skills` 未验证 |

### `browser-testing-with-devtools/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `browser-testing-with-devtools` | 进 `local/` | 无上游对应，本地维护 |

### `ci-cd-and-automation/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `ci-cd-and-automation` | 进 `local/` | 无上游对应，本地维护 |
| `ci-cd-and-automation/desktop-app-ci` | 进 `local/` | 无上游对应，本地维护 |
| `ci-cd-and-automation/desktop-app-qt6-ci` | 进 `local/` | 无上游对应，本地维护 |
| `ci-cd-and-automation/nix-flake-ci` | 进 `local/` | 无上游对应，本地维护 |

### `code-review-and-quality/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `code-review-and-quality` | 进 `local/` | 无上游对应，本地维护 |
| `code-review-and-quality/cpp-code-review` | 进 `local/` | 无上游对应，本地维护 |

### `code-simplification/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `code-simplification` | 进 `local/` | 无上游对应，本地维护 |

### `context-engineering/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `context-engineering` | 进 `local/` | 无上游对应，本地维护 |

### `deprecation-and-migration/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `deprecation-and-migration` | 进 `local/` | 无上游对应，本地维护 |

### `devops/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `devops/docker-compose-selfhost` | 进 `local/` | 无上游对应，本地维护 |
| `devops/hdd-pending-sector-repair` | 进 `local/` | 无上游对应，本地维护 |
| `devops/kanban-orchestrator` | 进 `local/` | 无上游对应，本地维护 |
| `devops/kanban-orchestrator.bak` | 不迁移 | `.bak` 备份目录，与主技能同源 |
| `devops/kanban-worker` | 进 `local/` | 无上游对应，本地维护 |
| `devops/kanban-worker.bak` | 不迁移 | `.bak` 备份目录，与主技能同源 |
| `devops/webhook-subscriptions` | 进 `local/` | 无上游对应，本地维护 |

### `documentation-and-adrs/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `documentation-and-adrs` | 进 `local/` | 无上游对应，本地维护 |

### `domain-name-brainstormer/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `domain-name-brainstormer` | 进 `local/` | 无上游对应，本地维护 |

### `email/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `email/himalaya` | 改上游 (`hermes/email/himalaya`) | 上游同名技能相似度 0.97 |
| `email/himalaya.bak` | 不迁移 | `.bak` 备份目录，与主技能同源 |

### `frontend-ui-engineering/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `frontend-ui-engineering` | 进 `local/` | 无上游对应，本地维护 |

### `git-workflow-and-versioning/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `git-workflow-and-versioning` | 进 `local/` | 无上游对应，本地维护 |

### `github/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `github/codebase-inspection` | 改上游 (`hermes/software-development/codebase-inspection`) | 上游同名技能相似度 1；上游路径为 `skills/software-development/codebase-inspection` |
| `github/github-auth` | 进 `local/` | 作者标记为 Hermes，但上游无对应技能；按本地维护 |
| `github/github-auth.bak` | 不迁移 | `.bak` 备份目录，与主技能同源 |
| `github/github-code-review` | 进 `local/` | 作者标记为 Hermes，但上游无对应技能；按本地维护 |
| `github/github-issues` | 进 `local/` | 作者标记为 Hermes，但上游无对应技能；按本地维护 |
| `github/github-pr-workflow` | 进 `local/` | 作者标记为 Hermes，但上游无对应技能；按本地维护 |
| `github/github-release-management` | 进 `local/` | 无上游对应，本地维护 |
| `github/github-repo-management` | 进 `local/` | 作者标记为 Hermes，但上游无对应技能；按本地维护 |

### `idea-refine/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `idea-refine` | 进 `local/` | 无上游对应，本地维护 |

### `incremental-implementation/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `incremental-implementation` | 进 `local/` | 无上游对应，本地维护 |

### `leisure/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `leisure/find-nearby` | 进 `local/` | 无上游对应，本地维护 |

### `mcp/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `mcp/mcporter` | 改上游 (`hermes-optional/mcp/mcporter`) | 上游同名技能相似度 1；上游路径为 `optional-skills/mcp/mcporter` |
| `mcp/native-mcp` | 进 `local/` | 作者标记为 Hermes，但上游无对应技能；按本地维护 |

### `media/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `media/gif-search` | 暂不迁移 | 上游一致（skills/media/gif-search），当前未在 claude/codex 启用；pin 后可直接启用 |
| `media/heartmula` | 暂不迁移 | 上游一致（optional-skills/creative/heartmula），当前未在 claude/codex 启用；pin 后可直接启用；上游路径为 `optional-skills/creative/heartmula` |
| `media/songsee` | 暂不迁移 | 上游一致（skills/media/songsee），当前未在 claude/codex 启用；pin 后可直接启用 |

### `nix-flake-development/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `nix-flake-development` | 进 `local/` | 无上游对应，本地维护 |

### `nix-module-capability-detection/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `nix-module-capability-detection` | 进 `local/` | 无上游对应，本地维护 |

### `note-taking/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `note-taking/obsidian` | 改上游 (`hermes/note-taking/obsidian`) | 上游同名技能相似度 1 |
| `note-taking/obsidian.bak` | 不迁移 | `.bak` 备份目录，与主技能同源 |

### `performance-optimization/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `performance-optimization` | 进 `local/` | 无上游对应，本地维护 |

### `planning-and-task-breakdown/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `planning-and-task-breakdown` | 进 `local/` | 无上游对应，本地维护 |

### `productivity/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `productivity/box` | 暂不迁移 | 上游一致（skills/productivity/box），当前未在 claude/codex 启用；pin 后可直接启用 |
| `productivity/document-to-action-items` | 暂不迁移 | 上游一致（skills/productivity/document-to-action-items），当前未在 claude/codex 启用；pin 后可直接启用 |
| `productivity/docx` | 暂不迁移 | 上游一致（skills/productivity/docx），当前未在 claude/codex 启用；pin 后可直接启用 |
| `productivity/maps` | 暂不迁移 | 上游一致（skills/productivity/maps），当前未在 claude/codex 启用；pin 后可直接启用 |
| `productivity/meeting-action-items` | 暂不迁移 | 上游一致（skills/productivity/meeting-action-items），当前未在 claude/codex 启用；pin 后可直接启用 |
| `productivity/nano-pdf` | 暂不迁移 | 未在 claude/codex 启用，且上游无对应 |
| `productivity/notion` | 暂不迁移 | 上游一致（skills/productivity/notion），当前未在 claude/codex 启用；pin 后可直接启用 |
| `productivity/pdf` | 暂不迁移 | 上游一致（skills/productivity/pdf），当前未在 claude/codex 启用；pin 后可直接启用 |
| `productivity/petdex` | 暂不迁移 | 未在 claude/codex 启用，且上游无对应 |
| `productivity/product-price-monitor` | 暂不迁移 | 上游一致（skills/productivity/product-price-monitor），当前未在 claude/codex 启用；pin 后可直接启用 |
| `productivity/session-librarian` | 暂不迁移 | 未在 claude/codex 启用，且上游无对应 |
| `productivity/teams-meeting-pipeline` | 暂不迁移 | 上游一致（skills/productivity/teams-meeting-pipeline），当前未在 claude/codex 启用；pin 后可直接启用 |
| `productivity/weekly-review-planning` | 暂不迁移 | 上游一致（skills/productivity/weekly-review-planning），当前未在 claude/codex 启用；pin 后可直接启用 |
| `productivity/xlsx` | 暂不迁移 | 上游一致（skills/productivity/xlsx），当前未在 claude/codex 启用；pin 后可直接启用 |

### `release-skills/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `release-skills` | 进 `local/` | 无上游对应，本地维护 |

### `security-and-hardening/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `security-and-hardening` | 进 `local/` | 无上游对应，本地维护 |

### `shell-scripting/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `shell-scripting` | 进 `local/` | 无上游对应，本地维护 |

### `shipping-and-launch/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `shipping-and-launch` | 进 `local/` | 无上游对应，本地维护 |

### `singbox-config/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `singbox-config` | 进 `local/` | 无上游对应，本地维护 |

### `social-media/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `social-media/xurl` | 改上游 (`hermes/social-media/xurl`) | 上游同名技能相似度 0.94 |

### `software-development/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `software-development/adding-rust-enum-variant` | 进 `local/` | 无上游对应，本地维护 |
| `software-development/c-development` | 进 `local/` | 无上游对应，本地维护 |
| `software-development/cargo-dependency-update` | 进 `local/` | 无上游对应，本地维护 |
| `software-development/cc-switch-app-type-wiring` | 进 `local/` | 无上游对应，本地维护 |
| `software-development/debugging-hermes-tui-commands` | 不迁移 | Hermes 运行时专用 |
| `software-development/design-md-init` | 进 `local/` | 无上游对应，本地维护 |
| `software-development/hermes-agent-skill-authoring` | 不迁移 | Hermes 运行时专用 |
| `software-development/node-inspect-debugger` | 改上游 (`hermes/software-development/node-inspect-debugger`) | 上游同名技能相似度 0.99 |
| `software-development/project-docs` | 进 `local/` | 无上游对应，本地维护 |
| `software-development/python-debugpy` | 改上游 (`hermes/software-development/python-debugpy`) | 上游同名技能相似度 0.91 |
| `software-development/requesting-code-review` | 改上游 (`hermes/software-development/requesting-code-review`) | 上游同名技能相似度 0.98 |
| `software-development/rust-pre-commit-hook` | 进 `local/` | 无上游对应，本地维护 |
| `software-development/rust-struct-field-propagation` | 进 `local/` | 无上游对应，本地维护 |
| `software-development/rust-test-isolation` | 进 `local/` | 无上游对应，本地维护 |
| `software-development/spike` | 改上游 (`hermes/software-development/spike`) | 上游同名技能相似度 1 |
| `software-development/subagent-driven-development` | 改上游 (`hermes-optional/software-development/subagent-driven-development`) | 上游同名技能相似度 1；上游路径为 `optional-skills/software-development/subagent-driven-development` |
| `software-development/systematic-debugging` | 进 `local/` | Hermes 改编版（obra/superpowers），已大幅改写（相似度 0.78） |
| `software-development/test-driven-development` | 改上游 (`hermes/software-development/test-driven-development`) | 上游同名技能相似度 0.94 |
| `software-development/writing-plans` | 进 `local/` | Hermes 改编版（obra/superpowers），已大幅改写（相似度 0.39） |

### `source-driven-development/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `source-driven-development` | 进 `local/` | 无上游对应，本地维护 |

### `spec-driven-development/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `spec-driven-development` | 进 `local/` | 无上游对应，本地维护 |

### `taysi/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `taysi/chinese-prose-lint` | 不迁移 | TaysiTsuki 仓库的 `home/agents/skills/` 是 source of truth |
| `taysi/code-cultivation` | 不迁移 | TaysiTsuki 仓库的 `home/agents/skills/` 是 source of truth |
| `taysi/group-meeting` | 不迁移 | TaysiTsuki 仓库的 `home/agents/skills/` 是 source of truth |
| `taysi/handoff` | 不迁移 | TaysiTsuki 仓库的 `home/agents/skills/` 是 source of truth |
| `taysi/host-system-convention` | 不迁移 | TaysiTsuki 仓库的 `home/agents/skills/` 是 source of truth |
| `taysi/humanizer` | 不迁移 | TaysiTsuki 仓库的 `home/agents/skills/` 是 source of truth |
| `taysi/prune-comments-and-docs` | 不迁移 | TaysiTsuki 仓库的 `home/agents/skills/` 是 source of truth |
| `taysi/sillytavern-card-backup` | 不迁移 | TaysiTsuki 仓库的 `home/agents/skills/` 是 source of truth |

### `test-driven-development/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `test-driven-development` | 待定 | 与 `software-development/test-driven-development` 重复，需二选一 |

### `using-agent-skills/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `using-agent-skills` | 进 `local/` | 无上游对应，本地维护 |

### `web-access/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `web-access` | 进 `local/` | 无上游对应，本地维护 |

### `workflow-skill-architect/`

| 技能目录 | 结论 | 依据 |
| --- | --- | --- |
| `workflow-skill-architect` | 进 `local/` | 无上游对应，本地维护 |

## 5. 不含 `SKILL.md` 的目录

agent-skills 只发现含 `SKILL.md` 的目录，以下内容不会被同步，也不进入清单：

| 目录 | 内容 | 处理 |
| --- | --- | --- |
| `diagramming/` `domain/` `feeds/` `gifs/` `inference-sh/` | 只有 `DESCRIPTION.md`，没有技能 | 忽略，可随 SSOT 一起归档 |
| `ui-ux-pro-max/` | 整个仓库检出（`skill.json`、`src/`、`cli/`、screenshots） | 需要时按上游 pin（Next Level Builder），不要复制进 `local/` |

## 6. 迁移批次

每个批次单独提交，顺序为「复制 → 登记 ID → `git add` → `just skills-check` →
（接管后）`just s`」。

```bash
# 以批次 1 为例
cp -a ~/.config/cc-switch-tui/skills/<rel> skills-nix/local/<rel>
# 编辑 skills-nix/catalog.nix，把 "local/<rel>" 加进 skills.enable
git add skills-nix/local skills-nix/catalog.nix
just skills-check
```

### 批次 1：Nix / 基础设施 / 本仓库流程（15 个）

- `ci-cd-and-automation/desktop-app-ci`
- `ci-cd-and-automation/desktop-app-qt6-ci`
- `ci-cd-and-automation/nix-flake-ci`
- `nix-flake-development`
- `nix-module-capability-detection`
- `singbox-config`
- `software-development/adding-rust-enum-variant`
- `software-development/c-development`
- `software-development/cargo-dependency-update`
- `software-development/cc-switch-app-type-wiring`
- `software-development/design-md-init`
- `software-development/project-docs`
- `software-development/rust-pre-commit-hook`
- `software-development/rust-struct-field-propagation`
- `software-development/rust-test-isolation`

### 批次 2：开发工作流与写作类（29 个）

- `api-and-interface-design`
- `autonomous-ai-agents/codex`
- `awesome-cv-customization`
- `browser-testing-with-devtools`
- `ci-cd-and-automation`
- `code-review-and-quality`
- `code-review-and-quality/cpp-code-review`
- `code-simplification`
- `context-engineering`
- `deprecation-and-migration`
- `documentation-and-adrs`
- `domain-name-brainstormer`
- `frontend-ui-engineering`
- `git-workflow-and-versioning`
- `idea-refine`
- `incremental-implementation`
- `performance-optimization`
- `planning-and-task-breakdown`
- `release-skills`
- `security-and-hardening`
- `shell-scripting`
- `shipping-and-launch`
- `software-development/systematic-debugging`
- `software-development/writing-plans`
- `source-driven-development`
- `spec-driven-development`
- `using-agent-skills`
- `web-access`
- `workflow-skill-architect`

### 批次 3：GitHub / DevOps / MCP（13 个）

- `devops/docker-compose-selfhost`
- `devops/hdd-pending-sector-repair`
- `devops/kanban-orchestrator`
- `devops/kanban-worker`
- `devops/webhook-subscriptions`
- `github/github-auth`
- `github/github-code-review`
- `github/github-issues`
- `github/github-pr-workflow`
- `github/github-release-management`
- `github/github-repo-management`
- `leisure/find-nearby`
- `mcp/native-mcp`

### 批次 4：改上游（13 个）

先落地 §3 的 manifest 与 lock，再把这批从 `local/` 排除，只启用上游 ID：

- `autonomous-ai-agents/claude-code` → `hermes/autonomous-ai-agents/claude-code`
- `autonomous-ai-agents/opencode` → `hermes/autonomous-ai-agents/opencode`
- `email/himalaya` → `hermes/email/himalaya`
- `github/codebase-inspection` → `hermes/software-development/codebase-inspection`
- `mcp/mcporter` → `hermes-optional/mcp/mcporter`
- `note-taking/obsidian` → `hermes/note-taking/obsidian`
- `social-media/xurl` → `hermes/social-media/xurl`
- `software-development/node-inspect-debugger` → `hermes/software-development/node-inspect-debugger`
- `software-development/python-debugpy` → `hermes/software-development/python-debugpy`
- `software-development/requesting-code-review` → `hermes/software-development/requesting-code-review`
- `software-development/spike` → `hermes/software-development/spike`
- `software-development/subagent-driven-development` → `hermes-optional/software-development/subagent-driven-development`
- `software-development/test-driven-development` → `hermes/software-development/test-driven-development`

## 7. 待确认

1. `test-driven-development`（顶层）与 `software-development/test-driven-development`
   内容不同（14K / 13K，后者与上游相似度 0.94）。保留上游对齐的那份，还是保留
   顶层那份？
2. `taysi/*` 8 个来自 TaysiTsuki 仓库的 `home/agents/skills/`。要不要在
   `skills-nix` 里用 flake 输入引用它（`input = "taysi"`、
   `subdir = "home/agents/skills"`），还是完全交给 TaysiTsuki 部署？
3. `hermes` pin 会拉入 366MB 仓库；如果只为 13 个技能，是否改为复制进 `local/`、
   放弃上游跟随？
4. `apple/*` 与 `macos-computer-use` 只在 handyMini 有意义，本轮是否一并处理？
5. 进入 `local/` 的 57 个里，有一部分可能已经不用了（SSOT 里还留着 6 个 `.bak`）。
   迁移时是否顺手删掉不再需要的？
6. `browser-act` 与 `productivity/{nano-pdf,petdex,session-librarian}` 上游不明，
   弃用还是保留本地副本？
7. 批次 2 里有 2 个是 Hermes 改编版但已大幅改写（`systematic-debugging` 0.78、
   `writing-plans` 0.39）：接受上游版本以减少自维护面，还是保留本地差异？
