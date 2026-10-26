# skills-nix 迁移记录

对应 `.github/docs/skills-nix-design.md` 与 `.github/docs/skills-nix-implementation.md`
的阶段 0–2。记录基线、已完成的验证、首次接管步骤、回滚方式，以及文档与实际
环境的差异。不记录任何凭据。

## 1. 基线（2026-10-26，buking）

| 项 | 值 |
| --- | --- |
| NixOS | 26.11.20261024.674a202 (Zokor) |
| `/run/current-system` | `nixos-system-buking-gitrev-7a4223c-26.11.20261024.674a202` |
| cc-switch-tui | 0.2.3 (1ebf7d4)，`skills.mode = managed` |
| `CODEX_HOME` | `~/.config/codex` |
| `CLAUDE_CONFIG_DIR` | `~/.config/claude` |
| `HERMES_HOME` | `~/.config/hermes` |
| `CC_SWITCH_TUI_CONFIG_DIR` | `~/.config/cc-switch-tui` |

Skills 目录现状：

| 目录 | SKILL.md | 顶层目录 | `.cc-switch-tui-managed` | `.agent-skills-managed.json` | 体积 |
| --- | --- | --- | --- | --- | --- |
| `~/.config/codex/skills` | 90（含 `.system` 5） | 46 | 45 | 无 | 6.8M |
| `~/.config/claude/skills` | 33 | 29 | 29 | 无 | 768K |
| `~/.config/opencode/skills` | 不存在 | – | – | – | – |
| `~/.gemini/skills` | 不存在 | – | – | – | – |
| `~/.config/cc-switch-tui/skills` | 111 | 49 | – | 无 | 6.9M |
| `~/.config/hermes/skills` | 190 | 63 | 44 | 无 | 39M |

补充事实：

- 目标目录里的技能都是真实目录，没有指向 store 的符号链接。
- Codex 的 `.system` 由 Codex 自己维护，`skills/.system/.codex-system-skills.marker`
  存在；四个目标目录都没有 `agent-skills-nix` 的归属 marker。
- 分级目录已经在实际使用，例如
  `~/.config/claude/skills/ci-cd-and-automation/nix-flake-ci/SKILL.md`。

## 2. 阶段状态

已完成（本分支）：

- 阶段 1：`skills-nix/` child flake、`home-manager.nix`、`catalog.nix`，
  根 flake 以 `path:./skills-nix` 引入，`home/default.nix` import 其 module。
- 阶段 1.2：两个本地技能（一个一级、一个二级目录），`idPrefix = "local"`。
- 阶段 2.1：`claude`、`codex`、`opencode`、`gemini` 四个 target 已启用，
  `codex` 保留默认的 `/.system` 排除。
- 阶段 2.2：层级、`idPrefix` 共存、`agents` 限制、未选中技能不进入 bundle
  的行为已用一次性 flake 验证（见 §3）。
- 生效范围收窄：只有 `catalog.nix` 的 `hosts` 列表（`buking`、`handyMini`）
  启用；其它 hosts 与 standalone Home Manager 求值出 `enable = false`。

未完成，按顺序阻塞：

1. 阶段 2.3 首次接管：需要先有备份、把要长期维护的 skills 搬进
   `skills-nix/local/`，并把 cc-switch-tui 切到 `external`。
2. 阶段 3 的运行时确认：`cc-switch-tui` 的 external 模式代码位于该仓库的
   `feat/skills-external-mode` 分支，本机运行的 0.2.3 仍是 managed 行为。
3. 阶段 4：从 cc-switch SSOT（111 个技能）逐项分类迁移。
4. 阶段 5：Hermes，未开始，也没有配置 target。

因此当前分支合入后**不要立刻执行 `just s`**：`claude` 与
`codex` 目录非空且没有归属 marker，同步程序会在改动任何目录前拒绝执行，
本次激活会失败。同步程序先校验全部目标再写入（`scripts/sync.sh` 的
`resolve_target_plan` 早于 `execute_target_plan`），所以失败不会留下半成品。

## 3. 验证记录

已执行并通过：

| 验证 | 命令 | 结果 |
| --- | --- | --- |
| child flake lock | `nix flake lock ./skills-nix` | 生成 `skills-nix/flake.lock` |
| catalog | `nix run ./skills-nix#skills-list` | 两个 ID：`local/skills-nix-maintenance`、`local/software-development/expnix-workflow` |
| bundle | `nix build ./skills-nix` | 目录层级 `local/<skill>`、`local/<category>/<skill>` 正确 |
| flake check | `nix flake check ./skills-nix` | 通过（check 即构建 bundle） |
| HM 求值 | `nix eval .#homeConfigurations.qi.activationPackage.drvPath` | 通过 |
| 激活脚本 | `nix eval --raw ...home.activation.agent-skills.data` | 调用 `skills-install` |
| 目标过滤 | `nix eval --json ...targetBundlePaths --apply builtins.attrNames` | `claude codex gemini opencode` |
| 重复同步 | 同一目标连续两次 `skills-install` | 幂等，技能链接不变 |
| 取消选择 | 从 catalog 删除一个 ID 后同步 | 目标目录中的该技能被删除 |
| 未标记目录 | 非空且无 marker 的目录 | 拒绝并返回 1，目录保持原样 |
| Codex 运行时 | `CODEX_HOME=/tmp/fakecodex codex debug prompt-input` | 两个技能都被发现，含二级目录技能 |
| idPrefix 共存 | 一次性 flake：同一路径两个前缀 | `local/...` 与 `mirror/...` 并存 |
| agents 限制 | 一次性 flake：`agents = [ "codex" ]` | 只出现在 codex 与完整 bundle |
| 空 agents | 一次性 flake：`agents = [ ]` | 只在完整 bundle 中，不进入任何 target |
| 主机范围 | `nix eval --json .#nixosConfigurations.<host>.config.home-manager.users.qi.programs.agent-skills.enable` | `buking`/`handyMini` 为 true；`nixwsl`/`reinsvps`/`debnsm`/standalone 为 false |

未执行，需要在接管后补做：

- `home-manager switch`（故意推迟，理由见 §2）。
- Claude、OMP/OpenCode、Gemini 的运行时发现验证：本机只安装了 `codex` 与
  `omp`，`claude` 只有 npm 全局包且没有非交互式技能列表命令，`gemini`
  未安装。记录为「未验证」，不能当作通过。
- `aarch64-darwin`（handyMini）与其它 hosts 的激活验证。

## 4. 首次接管步骤

固定顺序，任何一步没有完成都不要继续下一步。

```bash
# 1. 备份（放在仓库外，不进 git）
stamp=$(date +%Y%m%d-%H%M%S)
dest=~/backups/skills-nix-$stamp
mkdir -p "$dest"
rsync -a ~/.config/cc-switch-tui/skills/ "$dest/cc-switch-skills/"
rsync -a ~/.config/codex/skills/         "$dest/codex-skills/"
rsync -a ~/.config/claude/skills/        "$dest/claude-skills/"
rsync -a ~/.config/hermes/skills/        "$dest/hermes-skills/"
cp ~/.config/cc-switch-tui/cc-switch.db  ~/.config/cc-switch-tui/settings.json "$dest/"
du -sh "$dest"

# 2. cc-switch-tui 切到 external（TUI: Settings → Skills → mode）
#    或直接改 settings.json 的 {"skills": {"mode": "external"}} 后重启
#    确认它不再 sync、import，也不打包 skills.zip

# 3. 把要长期维护的技能按 § 阶段 4 分类后搬进 skills-nix/local/，
#    在 catalog.nix 的 skills.enable 里登记 ID，git add（flake 只读已跟踪文件）

# 4. 把旧目录整体移开（保留备份，不删除）
mv ~/.config/claude/skills ~/.config/claude/skills.pre-nix
mv ~/.config/codex/skills  ~/.config/codex/skills.pre-nix

# 5. 激活（NixOS / nix-darwin 用 just s；system-manager 主机用 just sysmgr）
just s

# 6. 把 Codex 的 .system 放回（同步程序按 /.system 排除，不会被删）
mv ~/.config/codex/skills.pre-nix/.system ~/.config/codex/skills/.system

# 7. 验证
cat ~/.config/claude/skills/.agent-skills-managed.json
find -L ~/.config/claude/skills ~/.config/codex/skills \
     ~/.config/opencode/skills ~/.gemini/skills -name SKILL.md | sort
CODEX_HOME=~/.config/codex codex debug prompt-input | rg 'skills-nix-maintenance'
```

不要设置 `AGENT_SKILLS_FORCE=1`：第 4 步之后目标目录是空的，
同步程序自己会写归属 marker，不需要强制覆盖。

## 5. 回滚

只回滚 Nix 侧：

```bash
# NixOS：system profile 承担 home-manager 的 generation
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
# 独立 Home Manager 才用 home-manager generations

# 回滚 skills-nix 的提交与 lock 后重新激活
git revert <skills-nix 相关提交>
just s
```

回到 cc-switch-tui 管理（顺序不能反）：

1. 把 `catalog.nix` 里的四个 target 关掉（或把 `hosts` 清空），`just s`，
   确认 Nix 不再写这些目录；
2. 删除或改名当前的 Nix 目标目录；
3. 从 §4 第 1 步的备份恢复 `~/.config/{claude,codex}/skills`；
4. 把 cc-switch 的 `skills.mode` 改回 `managed`；
5. 在 cc-switch 里手动 sync 一次；
6. 验证 provider 切换与 WebDAV restore 不会与 Nix 竞争。

## 6. 更新流程

```bash
# flake sources（含 agent-skills-nix 自身）
cd skills-nix
nix flake update
nix flake check .
cd ..

# registry sources（第一个上游 manifest 进入后才需要）
cd skills-nix
nix run .#skills-sources-lock
nix flake check .
```

审查顺序：lock diff → catalog diff → bundle 求值 → 四个 agent 的实际加载 →
提交 → `just s`。不做无人审查的定时覆盖。

## 7. 文档与实际的差异

1. 设计文档里的 `nix flake update --flake ./skills-nix` 在当前 Nix（2.34.9）
   不存在 `--flake` 参数，实际用法是进入 `skills-nix/` 后执行
   `nix flake update`。
2. `skills-sources-lock` 按当前工作目录解析 `registry/sources`，所以设计文档里的
   `nix run ./skills-nix#skills-sources-lock` 只有在 `skills-nix/` 目录内执行才指向
   本仓库的 manifest；在仓库根目录需要显式传 `--manifest-dir` 与 `--lock-file`。
3. 生效范围：`home/default.nix` 被所有 hosts 共用，所以 module 用
   `catalog.nix` 的 `hosts`（`buking`、`handyMini`）与 `hostName` 比对来决定是否
   启用。`hostName` 不能声明成模块参数：standalone Home Manager 不传它，
   声明后求值会直接失败，因此从 `args` 读取并回退到 `null`。设计文档没有写
   这一层限制，属于按机器类型的补充决策。
4. 设计文档 §2.2 说「`cc-switch-tui` 在 external 模式下不执行 Skills sync」，
   对应实现位于 cc-switch-tui 仓库的 `feat/skills-external-mode` 分支；本机运行的
   0.2.3 发布版仍是 managed 行为，接管前必须确认版本。
