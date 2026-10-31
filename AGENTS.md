# AGENTS.md

给在本仓库里工作的 AI agent 看的说明。内容与 `README.md` 互补：README 面向人，
这里只写"动手时要注意什么"。约定变化时请同步更新本文件。

## 项目概览

`expnix` 是个人 Nix flake 配置仓库，统一管理 NixOS、nix-darwin、system-manager
和 standalone Home Manager。部署入口只有本仓库。

| 路径 | 作用 |
| --- | --- |
| `flake.nix` | 输入、各类 configurations、devShells、formatter |
| `lib/` | `mkSystem`、`mkHome`、`mkSysMgr`、共享变量（`vars.nix`）、工具函数 |
| `hosts/<name>/` | 每台主机的系统配置 |
| `machines/` | 平台基础模块：`nix-core`、`wsl-base`、`orb-base`、`darwin-base` |
| `home/` | Home Manager 配置，按 `tui/`、`gui/` 分层 |
| `modules/` | 自定义 NixOS / nix-darwin / system-manager 模块 |
| `nixos/`、`overlays/`、`packages/` | 系统默认配置、overlay、自定义包 |
| `skills-nix/` | Agent Skills catalog（独立 flake、独立 lock） |

## 常用命令

| 任务 | 命令 |
| --- | --- |
| 进开发 shell | `./scripts/devshell-default.sh`（或 `nix develop`） |
| 切换系统 | `just s [host]`；system-manager 主机用 `just sysmgr` |
| 只切 Home Manager | `just switch-home`（日常一般直接用 `just s`） |
| 求值某主机 | `just evtop [host]`、`just ev-sysmgr [host]` |
| 格式化 | `nix fmt -- <files>` 或 `just nixfmt` |
| 安装 git hook | `just setup-hook` |
| 查看 Agent Skills | `just skills-list`、`just skills-check` |

## 提交前的验证

```bash
nix flake check --no-build
nix eval .#homeConfigurations.qi.activationPackage.drvPath --raw
nix build .#homeConfigurations.qi.activationPackage --dry-run
```

CI（`.github/workflows/ci.yml`）跑 `nix flake check`、`statix check .`，以及各
NixOS / darwin / Home Manager 输出的 `nix build --dry-run`。只改 Markdown、
`Justfile`、`.gitignore`、许可证时不会触发主 CI。

## 改动约定

- Profile 分层来自 `lib/vars.nix`：`tuiBase` 常开，`tuiAdvanced`、
  `tuiOptional`、`guiBase`、`guiHeavy` 由主机在 `flake.nix` 的
  `profileLevelOver` 里覆盖。
- `specialArgs` / `extraSpecialArgs` 提供 `inputs`、`myvars`、`myutils`、
  `profileLevel`、`homeDir`、`isDarwin`、`isLinux`、`isWSL`、`isHeLinux`、
  `isHmSingle`；standalone Home Manager **没有** `hostName`。
- 主机的服务配置放 `hosts/<host>/services.nix`，`default.nix` 只做接线。
- 密钥用 sops-nix + age：密文在 `secrets/` 与 `secrets/hosts/<host>/`，收件人
  在 `.sops.yaml`。不要提交明文，也不要给主机加它无法轮换的收件人。
- 每个 staged 的 `.nix` 文件必须通过 `nixfmt --check`（pre-commit hook 会拦）。
- 新增主机：建 `hosts/<name>/default.nix`（裸机还需要
  `hardware-configuration.nix`）→ 在 `flake.nix` 里注册并设置
  `profileLevelOver` → 加进 CI matrix。

## Agent Skills（`skills-nix/`）

细节见 `skills-nix/README.md`、来源见 `skills-nix/INVENTORY.md`、设计与偏差见
`.github/docs/skills-nix-design.md`。动手时记住这几点：

- **扁平只一层**：每个技能是 `<dest>/<name>/SKILL.md`，不要加分类目录，也不要
  把技能放进另一个技能目录（bundle 用软链物化技能，父子共用路径会冲突）。
  dsh 等 agent 只扫 skills 根目录一层。
- **上游优先**：上游有就引用（`catalog.nix` 的 `sources`），`local/` 只放没有
  上游的技能。
- **只部署 `skills.enable` 里列出的 ID**；按 agent 限制用 `skills.explicit` 的
  `agents`。
- **新文件要 `git add`**：flake 只读已跟踪文件，未跟踪的技能对求值不可见。
- 目标目录：`~/.agents/skills`（omp、pi、dsh）、`~/.config/claude/skills`、
  `~/.config/codex/skills`（排除 `/.system`）、`~/.config/opencode/skills`；
  只对 `catalog.nix` 的 `hosts`（`buking`、`handyMini`）启用。
- 改完跑 `just skills-check`；上游更新用 `cd skills-nix && nix flake update`，
  审查 lock diff 后再 `just s`。
- 边界：这四个目录的唯一写入者是 agent-skills-nix；`cc-switch-tui` 必须保持
  `skills.mode = "external"`；Hermes 的 `$HERMES_HOME/skills` 不要接管。
- 不要在没有审查的情况下设置 `AGENT_SKILLS_FORCE=1`：同步程序拒绝接管非空且
  没有自身 marker 的目录，这是保护，不是故障。
