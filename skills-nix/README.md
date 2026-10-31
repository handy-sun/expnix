# skills-nix

管理 Agent Skills 的 child flake：来源、选择，以及 Claude、Codex、
opencode 和共享 `~/.agents/skills` 的部署目标（omp、pi、dsh 都读后者）。部署入口仍然只有 `expnix`；
本 flake 只导出一个 Home Manager module，根 flake 用 `path:./skills-nix` 引入它。

## 结构

```text
skills-nix/
├── flake.nix        # module 输出、bundle package、check、apps
├── flake.lock       # 锁定 nixpkgs、agent-skills-nix 与上游技能仓库
├── catalog.nix      # sources、选中的 skills、hosts、targets
├── home-manager.nix # module 主体，读取 catalog.nix
└── local/           # 没有上游的技能（每个技能一个目录）
```

## 来源

`catalog.nix` 里没有任何 source 设置 `idPrefix`：**每个技能 ID 就是一个目录名**，
目标目录永远是 `<dest>/<name>/SKILL.md`。这样单层扫描器（dsh 读
`~/.agents/skills/<name>/SKILL.md`）也能发现全部技能。

| source | 上游 | 上游布局 | 取用方式 | 数量 |
| --- | --- | --- | --- | --- |
| `addyosmani` | `github:addyosmani/agent-skills` 的 `skills/` | 单层 | `enable` | 21 |
| `browser-act` | `github:browser-act/skills` | 单层（`filter.nameRegex`） | `enable` | 1 |
| `taysi` | `github:MidAutumnMoon/TaysiTsuki` 的 `home/agents/skills` | 单层 | `enable` | 11 |
| `local` | 本仓库 `local/` | 单层 | `enable` | 33 |

上游技能不复制进仓库：有上游就引用上游，`local/` 只放没有上游的项目专用技能，
外加 5 个从 Hermes toolkit 复制出来的小工具技能。`NousResearch/hermes-agent`
（271 MB 的 agent 运行时）没有作为输入引入，取舍见 `INVENTORY.md` §2。

## 命令

在仓库根目录：

```bash
just skills-list                            # 输出已启用技能的 JSON（不是全量 catalog）
nix build ./skills-nix && ls -R result/     # 查看渲染后的 bundle
just skills-check                           # nix flake check ./skills-nix
```

在 `skills-nix/` 目录：

```bash
nix flake update         # 刷新 flake.lock（nixpkgs、agent-skills-nix 与上游技能仓库）
nix run .#skills-install # 手动同步已启用的 targets
```

`skills-install` 会写真实目标目录。只想检查结果时用
`AGENT_SKILLS_DESTS=/tmp/skills-preview` 指向临时目录。

## 目标目录

| Target | 目录 | 说明 |
| --- | --- | --- |
| `agents` | `$HOME/.agents/skills` | 共享目录；dsh 把它当作 user-agents root |
| `claude` | `$HOME/.config/claude/skills` | 显式路径，等于 `home/default.nix` 里的 `CLAUDE_CONFIG_DIR` |
| `codex` | `$HOME/.config/codex/skills` | 显式路径；排除 `/.system`，Codex 自己维护 bundled skills |
| `opencode` | `$HOME/.config/opencode/skills` | 只服务 opencode CLI；omp/pi 走 `agents` |

`claude` 与 `codex` 没有用模块默认的 `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills`
形式：Home Manager 的激活由 `home-manager-<user>.service` 执行，该 unit 的环境里
没有 `CLAUDE_CONFIG_DIR` / `CODEX_HOME`，变量会回退到 `~/.claude`、`~/.codex`，
而 agent 从登录 shell 读的是 XDG 路径。

全局目标使用 `symlink-tree`：激活时用 `rsync -a --delete` 从 store bundle
同步，并在目标目录写入 `.agent-skills-managed.json` 表示归属。目标目录非空且
没有该 marker 时，同步会拒绝而不是覆盖；校验在写入前完成，失败不会留下半截状态。

只有 `catalog.nix` 的 `hosts`（`buking`、`handyMini`）会启用这四个目标；
其它 hosts 和 standalone Home Manager 求值出 `enable = false`，不会创建目录。
`skills-install` 是手动入口，不受 `hosts` 限制。

Hermes 不是 target。`$HERMES_HOME/skills` 混合了 bundled skills、
`.bundled_manifest`、`.archive` 和 curator 状态，`rsync --delete` 会删掉
本 flake 并不拥有的内容。

## 首次接管与回滚

接管记录（2026-10-26）：备份在
`~/backups/skills-nix-takeover-20261026-135340`（SSOT 全量副本、
`cc-switch.db`、`settings.json`、旧的 `claude-skills.old` / `codex-skills.old`）。
当时的做法是：旧目录整体 `mv` 进备份 → 四目标首次同步 → 把 Codex 的
`.system` 拷回（同步按 `/.system` 排除，之后的重同步不会删）。

回滚只回 Nix 侧：

```bash
git revert <skills-nix 相关提交>
just s
```

回到 cc-switch-tui 管理（顺序不能反）：清空 `catalog.nix` 的 `hosts` 并
`just s` → 删除当前 Nix 目标目录 → 从备份恢复旧目录 → 把 cc-switch 的
`skills.mode` 改回 `managed` → 手动 sync 一次 → 验证 provider 与 WebDAV
不会与 Nix 竞争。不要只改设置而保留 Nix target 激活。

## 边界

- 上面四个目录的唯一写入者是 `agent-skills-nix`。
- `cc-switch-tui` 必须处于 `skills.mode = "external"`，此时它跳过 skills
  同步、导入和 WebDAV 的 `skills.zip`。
- MCP server、provider、模型、凭据和 agent 原生 tool registry 不是 skill，
  继续由 `cc-switch-tui` 或 agent 自身配置管理。
- 上游 skills 只能通过审查过的 lock 变更进入。

来源清单见 `INVENTORY.md`；设计依据与偏差记录见
`.github/docs/skills-nix-design.md`。
