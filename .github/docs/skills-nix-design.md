# Skills 管理设计：agent-skills-nix 接入 expnix

本文记录**已经落地**的 Skills 管理方案：来源、选择、目标目录、更新与回滚。
设计过程中的取舍与偏差记在 §9；旧版本里的 registry、`idPrefix`、Gemini target
等未采用的方案不再保留。

## 1. 目标和范围

Agent Skills 的声明、选择、目标目录和上游更新交给
[agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix)，并接入现有
`expnix` 的 Home Manager 部署链路。

cc-switch-tui 继续负责 provider、MCP、prompt、代理和 WebDAV 等配置；它的
Skills 功能切换为 `external` 模式后，不再写入任何 agent 的 Skills 目录。

覆盖范围：

- Claude、Codex、OpenCode/OMP 的全局 Skills，以及共享的 `~/.agents/skills`；
- `expnix/skills-nix/` 里的上游 source、本地 Skills 和选择列表；
- 扁平化的目录层级、按 agent 选择、宿主范围；
- flake lock 的更新策略；
- cc-switch-tui 的禁用边界、数据迁移、WebDAV 和回滚；
- Hermes 的边界处理。

不把 MCP server、provider、hooks 或 Hermes gateway 工具包装成 Skill。

## 2. 决策

### 2.1 独立 child flake

```text
expnix/
└── skills-nix/
    ├── flake.nix         # module 输出、bundle package、check、apps
    ├── flake.lock        # nixpkgs、agent-skills-nix、三个上游技能仓库
    ├── catalog.nix       # sources、选中的 skills、hosts、targets
    ├── home-manager.nix  # module 主体
    └── local/            # 没有上游的技能
```

根 flake 通过 `path:./skills-nix` 引入，`home/default.nix` import 它导出的
Home Manager module。部署入口仍然只有 `expnix`，不会产生第二套 generation。

不采用完全独立的 Home Manager 项目（会与 expnix 的 home switch 互相覆盖），
也不把上游 source 塞进根 flake（Skills 的生命周期与系统模块不同）。

### 2.2 唯一写入者

| 目标 | 目录 | 说明 |
| --- | --- | --- |
| `agents` | `$HOME/.agents/skills` | 共享目录；dsh 把这里当作 user-agents root |
| `claude` | `$HOME/.config/claude/skills` | 等于 `home/default.nix` 里的 `CLAUDE_CONFIG_DIR` |
| `codex` | `$HOME/.config/codex/skills` | 等于 `CODEX_HOME`；排除 `/.system` |
| `opencode` | `$HOME/.config/opencode/skills` | 只服务 opencode CLI；omp/pi 走 `agents`（见 §2.4） |
| Hermes 的 `skills` 根目录 | 不接管 | 保留 bundled skills、`.bundled_manifest` 与 curator 状态 |
| `~/.dsh/skills` | 不接管 | dsh 自己的目录，已清空，改由 `agents` 目标提供 |

`claude` 与 `codex` 不用模块默认的 `${CLAUDE_CONFIG_DIR:-...}/skills` 形式：
Home Manager 激活由 `home-manager-<user>.service` 执行，该 unit 的环境里没有
`CLAUDE_CONFIG_DIR` / `CODEX_HOME`，变量会回退到 `~/.claude`、`~/.codex`，
而 agent 从登录 shell 读的是 XDG 路径。

### 2.3 扁平的目标目录结构

**每个技能 ID 就是一个目录名**，目标目录统一是 `<dest>/<name>/SKILL.md`：

```text
~/.config/claude/skills/
├── api-and-interface-design/SKILL.md
├── python-debugpy/SKILL.md
└── ...
```

原因：dsh 的技能加载器（`@deepseek-ai/dsh-skill-filesystem` 的
`discoverRoot`）只列 skills 根目录的一层，`<root>/<name>/SKILL.md` 之外的内容
不会被发现；`~/.agents/skills` 也是同样的扫描方式。带 `idPrefix`、分类目录或
父子技能嵌套的布局对这些 agent 完全不可见。Codex 虽然能递归，但扁平对全部
agent 都成立。

全局目标使用 `symlink-tree`：技能在 Nix store 里生成 bundle，激活时用
`rsync -a --delete` 同步，并在目标目录写入 `.agent-skills-managed.json`。
目标目录非空且没有该 marker 时，同步会拒绝而不是覆盖；校验在写入前完成，
失败不会留下半截状态。

### 2.4 omp 与 pi 走 `agents`，opencode 目标只服务 opencode CLI

早期版本把 `omp` 当成 OpenCode 生态的二进制，让它复用
`~/.config/opencode/skills`。**这个假设是错的**，实测（omp 18.11.0）：

| 事实 | 证据 |
| --- | --- |
| omp 是 pi 的分支，不是 opencode | 二进制里是 `pi_natives` 原生模块，家目录 `~/.omp`，agent 状态在 `~/.omp/agent` |
| omp 读 `~/.agents/skills` 和 `~/.omp/agent/skills` | 二进制里的说明是 "Load skills from `.agent/skills` and `.agents/skills` (project walk-up + user home)"；往 `~/.omp/agent/skills` 放一个探针技能能被 `omp skill list` 列出 |
| omp **不读** `~/.config/opencode/skills` | 把该目录移走后 `omp skill list` 条数不变（当时部署 68 个）；把 `~/.agents/skills` 移走后变成 0 条 |
| `~/.config/opencode` 只用于 opencode 的认证/模型集成 | 二进制里有 `https://opencode.ai/auth`、`auth/opencode-go.kdl` 之类，没有 skills 路径 |

因此：

- `agents` 目标（`$HOME/.agents/skills`）同时服务 omp、pi 和 dsh；
- `opencode` 目标只对真正的 opencode CLI 有意义（本机未安装，保留为可选）；
- pi 自己的技能目录是 `~/.pi/agent/skills`（可用 `PI_CODING_AGENT_DIR` 覆盖），
  omp 对应 `~/.omp/agent/skills`，两者互不相通。

### 2.5 Hermes 不接管

`~/.config/hermes/skills` 同时包含 Hermes 自带技能、`.bundled_manifest`、
`.archive` 和 curator 数据。`rsync --delete` 接管整个根目录会删掉这些内容，
所以不配置 `targets.hermes`。

cc-switch 曾经往这个目录写过 80 个与旧 SSOT 同名的副本。2026-10-26 已把它们
（以及空的分类目录和 `ui-ux-pro-max` 检出）移到
`~/backups/hermes-skills-20261026-152916/`，Hermes 只剩它自带的 35 个技能。

### 2.6 宿主范围

`home/default.nix` 被所有 hosts 共用，module 用 `hostName` 与
`catalog.nix` 的 `hosts`（`buking`、`handyMini`）比对来决定是否启用：

```nix
{ catalog }:
{ lib, ... }@args:
let
  hostName = args.hostName or null;
  enabled = hostName != null && builtins.elem hostName catalog.hosts;
in
{
  programs.agent-skills = lib.mkIf enabled { ... };
}
```

`hostName` 不能声明成模块参数：standalone Home Manager 不传它，声明后求值会
直接失败，因此从 `args` 读取并回退到 `null`。其它 hosts（服务器、standalone）
求值出 `enable = false`，不会创建目录。

## 3. Source of truth

### 3.1 上游优先

能引用上游的一律引用，不复制内容：

| source | 仓库 | 布局 | 取用 | 数量 |
| --- | --- | --- | --- | --- |
| `addyosmani` | `github:addyosmani/agent-skills` 的 `skills/` | 单层 | `enable` | 21 |
| `browser-act` | `github:browser-act/skills` | 仓库根下 `browser-act/` | `filter.nameRegex` | 1 |
| `taysi` | `github:MidAutumnMoon/TaysiTsuki` 的 `home/agents/skills` | 单层 | `enable` | 11 |
| `local` | 本仓库 `local/` | 单层 | `enable` | 33 |

上游仓库都是 `flake = false` 输入，只取源码树，不评估它们的 flake outputs。

`NousResearch/hermes-agent` **不是输入**：它是 271 MB 的 agent 运行时，其中与
这里相关的只有 12 个技能——5 个与 agent 无关的工具技能复制进 `local/`，其余
依赖 Hermes 自身工具或运行时的技能（`claude-code`、`opencode`、
`subagent-driven-development` 等）没有采用。

### 3.2 本地技能

`skills-nix/local/` 只放没有上游的技能，每个技能一个目录：

```text
skills-nix/local/
├── nix-flake-development/SKILL.md
├── rust-test-isolation/SKILL.md
└── ...
```

两条硬规则：

- **只允许单层。** 不放分类目录，也不放"技能里的技能"：bundle 把技能物化成
  指向其目录的软链，父级与子级不能共用路径，而且多一层目录对单层扫描器不可见。
  分类信息放进文件名或 front matter。
- **上游优先。** 有上游就不要复制；例外是体积过大的 Hermes 运行时。

当前 33 个本地技能按用途分成 Nix/基础设施、CI 与桌面打包、Rust、C/Shell、
GitHub、开发工作流、文档写作、运维自托管、工具几组，逐条说明见
`skills-nix/local/README.md`。

只对本仓库有意义的说明不放进技能，而是写在仓库根的 `AGENTS.md`（Claude Code
读 `CLAUDE.md`，它是指向同一个文件的软链）。`expnix-workflow` 和
`skills-nix-maintenance` 原先就是两个全局技能，现在并入了那里：它们不该在别的
仓库里占用全局技能列表和元数据预算。

### 3.3 命名与选择

- 所有 source 都不设 `idPrefix`；
- 只在 `catalog.nix` 的 `skills.enable` 里列出的技能会被部署；
- 需要按 agent 限制时用 `skills.explicit`（`agents = [ "codex" ]`），
  上游布局是多层时也可以用它把 ID 压平。

## 4. 定制能力边界

可以由 agent-skills-nix 管理：本地 Skill 文件与附属脚本、上游 source、只启用
指定 Skills、按 target 限制、`transform` 改写 `SKILL.md`、`packages` 放入
CLI 依赖、全局与项目本地同步目标。

不由它管理：MCP server 注册、agent 全局 tool registry、Hermes gateway
toolset、provider/模型/凭据/代理，以及 cc-switch-tui 的 WebDAV、数据库和 UI
状态。`packages` 只给 Skill 文档提供命令行依赖，不等于给 agent 增加原生 tool。

## 5. 上游更新模型

上游固定在 `skills-nix/flake.lock`，只有一层锁：

```bash
cd skills-nix
nix flake update   # nixpkgs、agent-skills-nix 与三个上游技能仓库
nix flake check .
```

审查顺序：lock diff → `catalog.nix` diff → bundle 求值 → 各 agent 的实际加载
→ 提交 → `just s`。上游更新不会自动写用户目录。

设计早期曾计划用 npins 生成 `registry/sources.lock.json`；实际全部 source 都是
flake input，多一层锁只增加维护面，`skills-nix/registry/` 已删除。

## 6. cc-switch-tui 外部管理模式

配置项 `skills.mode = managed | external`，默认 `managed`。`external` 的行为：

1. 不创建、迁移或写入 cc-switch-tui Skills SSOT；
2. 不执行 `sync_all_enabled_best_effort()`；
3. provider 切换、配置恢复和 WebDAV restore 跳过 Skills；
4. install/uninstall/enable/disable/sync/import 等写操作返回外部管理提示；
5. Skills 页面保留只读状态，不把外部目录导入数据库；
6. WebDAV 不打包或恢复 `skills.zip`；
7. 切换模式不删除现有 Skills 文件。

实现位于 cc-switch-tui 仓库（`SkillsMode`、`SkillService` 的写保护、provider
live-flow、WebDAV archive/restore、CLI/TUI 提示与测试）。本机已切到
`external`，`settings.json` 里是 `{"skills":{"mode":"external"}}`。

## 7. 接管记录与回滚

### 7.1 接管（2026-10-26）

前置：cc-switch 切 external；备份目录
`~/backups/skills-nix-takeover-20261026-135340`（SSOT 全量副本、
`cc-switch.db`、`settings.json`、旧的 `claude-skills.old` / `codex-skills.old`）。

```bash
# 1. 旧目录整体移进备份，目标位置变空
mv ~/.config/claude/skills "$base/claude-skills.old"
mv ~/.config/codex/skills  "$base/codex-skills.old"

# 2. 首次同步（四个目标，显式给出配置目录）
CLAUDE_CONFIG_DIR=~/.config/claude CODEX_HOME=~/.config/codex \
  nix run ./skills-nix#skills-install

# 3. 把 Codex 的 .system 放回（同步按 /.system 排除，之后的重同步不会删）
cp -a "$base/codex-skills.old/.system" ~/.config/codex/skills/.system
```

没有使用 `AGENT_SKILLS_FORCE=1`：同步前目标目录是空的，程序自己写归属 marker。

### 7.2 回滚

只回滚 Nix 侧：

```bash
# NixOS 的 home-manager generation 由 system profile 承担
sudo nix-env -p /nix/var/nix/profiles/system --list-generations

git revert <skills-nix 相关提交>
just s
```

回到 cc-switch-tui 管理（顺序不能反）：

1. 把 `catalog.nix` 的 `hosts` 清空（或关掉各 target），`just s`，确认 Nix
   不再写这些目录；
2. 删除或改名当前的 Nix 目标目录；
3. 从 `~/backups/skills-nix-takeover-*` 恢复 `claude-skills.old`、
   `codex-skills.old`；
4. 把 cc-switch 的 `skills.mode` 改回 `managed`；
5. 在 cc-switch 里手动 sync 一次；
6. 验证 provider 切换与 WebDAV restore 不会与 Nix 竞争。

### 7.3 其它备份

| 目录 | 内容 |
| --- | --- |
| `~/backups/skills-nix-takeover-20261026-135340` | 接管前的 agent 目录、cc-switch SSOT 与数据库、移出的 15 个旧目录 |
| `~/backups/hermes-skills-20261026-152916` | 从 Hermes 移出的 80 个 SSOT 副本、`gemini-skills`、`cc-switch-residue` |
| `~/backups/dsh-skills-20261026-150309` | `~/.dsh/skills` 里 4 个手工副本 |

## 8. 验收标准

- `nix flake check ./skills-nix` 通过，bundle 里 66 个技能全部是单层；
- expnix Home Manager evaluation 能找到 module，`buking` / `handyMini` 为
  `enable = true`，其它 hosts 为 `false`；
- 四个目标只包含预期的 66 个技能，Codex `.system` 未被覆盖；
- provider 切换、恢复、WebDAV 操作不改变外部 Skills；
- cc-switch external 模式下所有 Skills 写操作都有明确提示；
- Codex 与 dsh 已验证能加载全部技能；Claude、OMP 待运行时确认；
- 上游更新只通过 `flake.lock` 变更进入系统；
- Hermes 自带技能、`.bundled_manifest` 与 `.archive` 保持原状。

## 9. 与最初设计的偏差

| 原方案 | 实际 | 原因 |
| --- | --- | --- |
| `idPrefix` 做命名空间、允许分级目录 | 全部扁平，不用 `idPrefix` | dsh 只扫一层；多一层目录对它不可见 |
| Gemini 作为第四个 agent target | 只有 `agents`、`claude`、`codex`、`opencode` | 本机不用 gemini |
| registry manifest + npins 锁 | 只用 flake input | 全部 source 都是 flake input，多一层锁无收益 |
| 目标用 `${VAR:-$HOME/...}` 默认值 | claude/codex 显式 XDG 路径 | HM 激活的 systemd unit 里没有那两个变量 |
| 接管前把长期技能复制进 `local/` | 上游优先，`local/` 只放无上游技能 | 减少重复维护 |
| `nix flake update --flake ./skills-nix` | 进目录执行 `nix flake update` | 当前 Nix 没有该参数 |
