# skills-nix

管理 Agent Skills 的 child flake：来源、选择，以及 Claude、Codex、
OpenCode/OMP、Gemini 的目标目录。部署入口仍然只有 `expnix`；本 flake 只导出
一个 Home Manager module，根 flake 用 `path:./skills-nix` 引入它。

## 结构

```text
skills-nix/
├── flake.nix        # module 输出、bundle package、check、apps
├── flake.lock       # 锁定 nixpkgs 与 agent-skills-nix
├── catalog.nix      # sources、选中的 skills、启用的 targets
├── home-manager.nix # module 主体，读取 catalog.nix
├── local/           # 本仓库维护的 skills
└── registry/        # 上游仓库的 manifest 与 lock（见其 README）
```

## 来源

`catalog.nix` 里没有任何 source 设置 `idPrefix`：**每个技能 ID 就是一个目录名**，
目标目录永远是 `<dest>/<name>/SKILL.md`。这样单层扫描器（DSH 读
`~/.dsh/skills/<name>/SKILL.md`、`~/.agents/skills/<name>/SKILL.md`）也能发现全部
技能。

| source | 上游 | 上游布局 | 取用方式 | 数量 |
| --- | --- | --- | --- | --- |
| `addyosmani` | `github:addyosmani/agent-skills` 的 `skills/` | 单层 | `enable` | 20 |
| `hermes` | `github:NousResearch/hermes-agent` 的 `skills/` | `<category>/<name>` | `explicit` 改名压平 | 10 |
| `hermes-optional` | 同仓库的 `optional-skills/` | 同上 | `explicit` 改名压平 | 2 |
| `browser-act` | `github:browser-act/skills` | 单层（`filter.nameRegex`） | `enable` | 1 |
| `taysi` | `github:MidAutumnMoon/TaysiTsuki` 的 `home/agents/skills` | 单层 | `enable` | 8 |
| `local` | 本仓库 `local/` | 单层 | `enable` | 40 |

上游技能不再复制进仓库：上游有就引用上游，`local/` 只放没有上游的项目专用技能。
`hermes` 的两个 source 指向同一个约 271MB 的运行时仓库，只为 12 个技能，是这套
配置里唯一体积明显的输入。

## 命令

在仓库根目录：

```bash
just skills-list                            # 输出已启用技能的 JSON（不是全量 catalog）
nix build ./skills-nix && ls -R result/     # 查看渲染后的 bundle
just skills-check                           # nix flake check ./skills-nix
```

在 `skills-nix/` 目录：

```bash
nix run .#skills-sources-lock   # 刷新 registry/sources.lock.json
nix flake update                # 刷新 flake.lock
nix run .#skills-install        # 手动同步已启用的 targets
```

`skills-install` 会写真实目标目录。只想检查结果时用
`AGENT_SKILLS_DESTS=/tmp/skills-preview` 指向临时目录。

lock 更新程序按当前工作目录解析 `registry/sources`，因此要在
`skills-nix/` 下运行；在仓库根目录也可以显式传参：

```bash
nix run ./skills-nix#skills-sources-lock -- \
  --manifest-dir skills-nix/registry/sources \
  --lock-file skills-nix/registry/sources.lock.json
```

## 目标目录

| Target | 目录 | 说明 |
| --- | --- | --- |
| `claude` | `$HOME/.config/claude/skills` | 显式路径，等于 `home/default.nix` 里的 `CLAUDE_CONFIG_DIR` |
| `codex` | `$HOME/.config/codex/skills` | 显式路径；排除 `/.system`，Codex 自己维护 bundled skills |
| `opencode` | `$HOME/.config/opencode/skills` | 与 OMP 共用 |
| `gemini` | `$HOME/.gemini/skills` | |

`claude` 与 `codex` 没有用模块默认的 `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills`
形式：Home Manager 的激活由 `home-manager-<user>.service` 执行，该 unit 的环境里
没有 `CLAUDE_CONFIG_DIR` / `CODEX_HOME`，变量会回退到 `~/.claude`、`~/.codex`，
而 agent 从登录 shell 读的是 XDG 路径。

全局目标使用 `symlink-tree`：激活时用 `rsync -a --delete` 从 store bundle
同步，并在目标目录写入 `.agent-skills-managed.json` 表示归属。目标目录非空且
没有该 marker 时，同步会拒绝而不是覆盖。

只有 `catalog.nix` 的 `hosts`（`buking`、`handyMini`）会启用这四个目标；
其它 hosts 和 standalone Home Manager 求值出 `enable = false`，不会创建目录。
`skills-install` 是手动入口，不受 `hosts` 限制。

Hermes 不是 target。`$HERMES_HOME/skills` 混合了 bundled skills、
`.bundled_manifest`、`.archive` 和 curator 状态，`rsync --delete` 会删掉
本 flake 并不拥有的内容。

## 边界

- 上面四个目录的唯一写入者是 `agent-skills-nix`。
- `cc-switch-tui` 必须处于 `skills.mode = "external"`，此时它跳过 skills
  同步、导入和 WebDAV 的 `skills.zip`。
- MCP server、provider、模型、凭据和 agent 原生 tool registry 不是 skill，
  继续由 `cc-switch-tui` 或 agent 自身配置管理。
- 上游 skills 只能通过审查过的 lock 变更进入。

基线数据、首次接管步骤和回滚方式见 `MIGRATION.md`；cc-switch SSOT 里 111 个
技能的逐项分类结论见 `INVENTORY.md`；设计依据见
`.github/docs/skills-nix-design.md`。
