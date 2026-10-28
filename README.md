# expnix

个人 Nix flake 配置仓库，用来统一管理 NixOS、nix-darwin、standalone Home Manager 和 system-manager 环境。仓库把系统配置、Home Manager 配置、常用开发工具、图形/终端 profile、私有 dotfiles 输入和 CI 校验放在同一套 flake 工作流里。

## 管理的机器

| 名称 | 类型 | 系统 | 说明 | 闭包大小 |
| --- | --- | --- | --- | --- |
| `buking` | NixOS | `x86_64-linux` | 物理 Linux 桌面环境，启用完整 GUI profile | 38.5GiB |
| `reinsvps` | NixOS | `x86_64-linux` | VPS / 服务器环境 | 10GiB |
| `txsh011` | NixOS | `x86_64-linux` | VPS / 服务器环境，只启用 `tuiBase` | 8GiB |
| `nixwsl` | NixOS-WSL | `x86_64-linux` | WSL2 环境，启用 `tuiOptional` | 11GiB |
| `handyMini` | nix-darwin | `aarch64-darwin` | macOS 环境，启用 `tuiOptional` 和 `guiBase` | 13GiB |
| `debnsm` | system-manager | `x86_64-linux` | 非 NixOS Linux 主机配置，启用 system-manager 和 Home Manager | / |
| `qi(deprecated)` | Home Manager | `x86_64-linux` | standalone Home Manager 配置 | / |
| `orbvmnix(not used)` | NixOS | `aarch64-linux` | OrbStack / 虚拟化 Linux 环境，启用 `tuiOptional` | / |

## 首次引导

所有命令默认在仓库根目录执行。

首次进入开发 shell（需要启用 flakes 和 nix-command）：

```bash
## 等同于 nix develop --experimental-features "nix-command flakes"
./scripts/devshell-default.sh
```

**如果是非NixOS系统，要进入system-manager的开发环境**

```bash
./scripts/devshell-sysmgr.sh
```


开发 shell 会通过 `NIX_CONFIG` 为 shell 内的命令启用 `nix-command` 和 `flakes`，并配置国内 substituter。若本机尚未允许 flake，首次运行时保留上面的 `--experimental-features` 参数即可。

默认开发 shell 提供 `git`、`just`、`nh`、`nix-output-monitor`、`age` 和 `sops` 等工具。进入后建议先安装本仓库的 git hook：

```bash
just setup-hook
```

激活当前主机的系统配置：

```bash
just switch
```

`just switch` 会按平台分发：Linux 上执行 `nh os switch .`，macOS 上执行 `nh darwin switch .`。

只切换 Home Manager，不重建整个系统：

```bash
just switch-home
```

部署 `debnsm` 这类非 NixOS Linux 主机时使用 system-manager：

```bash
just sysmgr
```

## 常用命令

| 命令 | 说明 |
| --- | --- |
| `just` | 查看所有可用 recipe |
| `just setup-hook` | 设置 `.githooks` 为当前仓库的 git hooks 目录 |
| `just switch` | 激活当前机器的 NixOS 或 nix-darwin 配置 |
| `just switch-home` | 只激活 Home Manager 配置 |
| `nix fmt -- <files>` | 对指定 Nix 文件调用 flake 暴露的 formatter |
| `just nixfmt` | 扫描仓库中的 `.nix` 文件并运行 `nixfmt` |
| `just repl` | 打开当前 flake 的 `nix repl` |
| `just repl-flake` | 打开 nixpkgs flake 的 `nix repl` |
| `just repl-pkgs` | 打开当前 nixpkgs package set 的 `nix repl` |
| `just repl-nh` | 打开当前系统的 `nh os repl` 或 `nh darwin repl` |
| `just evtop [host]` | 求值指定主机的 system toplevel derivation |
| `just ev-sysmgr [host]` | 求值指定 system-manager 主机的 toplevel derivation |
| `just current-sys` | 查看 `/run/current-system` 当前指向 |
| `just history` | 查看系统 profile 历史 |
| `just list-generations` | 列出系统 profile generations |
| `just gc` | 清理 4 天前的未使用 Nix store 条目 |
| `just skills-list` | 列出 `skills-nix` 选中的 Agent Skills |
| `just skills-check` | 检查 `skills-nix` child flake（会构建 bundle） |

## 更新流程

仓库把不同来源的 flake input 分成几类更新，便于减少不相关变更混在一起：

| 命令 | 更新范围 |
| --- | --- |
| `just upc-nix` | 更新 Nix 生态相关输入，并自动提交 `flake.lock` |
| `just upc-my` | 更新个人 dotfiles / 脚本类输入，并自动提交 `flake.lock` |
| `just up-my` | 更新个人 dotfiles / 脚本类输入，但不自动提交 |

`.github/workflows/update-deps.yml` 目前只支持手动触发；它会更新选定的 Nix 生态输入并推送 `automation/update-flake-inputs` 分支。定时触发配置暂时处于注释状态。

## 格式化和提交检查

当前项目常用的两个格式化入口是：

```bash
just nixfmt
nix fmt -- <files>
```

`flake.nix` 暴露的 formatter 是 `nixfmt-rs`；批量格式化可以运行 `just nixfmt`，只格式化指定文件则使用 `nix fmt -- <files>`。`.githooks/pre-commit` 会对 staged 的 `.nix` 文件运行：

```bash
nixfmt --check <staged-nix-files>
```

如果 hook 失败，先运行 `nixfmt <staged-nix-files>` 或 `just nixfmt`，重新 `git add` 格式化后的文件，再提交。

## 项目结构

| 路径 | 作用 |
| --- | --- |
| `flake.nix` | flake 输入、系统输出、Home Manager 输出、dev shell、formatter |
| `flake.lock` | 锁定所有 flake input 的版本 |
| `lib/` | `mkSystem`、`mkHome`、共享变量和工具函数 |
| `hosts/` | 每台机器的主机级配置 |
| `machines/` | NixOS、WSL、OrbStack、Darwin 的平台基础配置 |
| `home/` | Home Manager 配置，按 TUI / GUI / 包分层组织 |
| `modules/` | 自定义 NixOS / nix-darwin 模块 |
| `overlays/` | 自定义 package overlay |
| `nixos/` | NixOS 通用配置和服务配置 |
| `packages/` | 自定义 package 定义和 NixPak 应用 |
| `skills-nix/` | Agent Skills catalog：来源、选择、目标目录，独立 flake 与 lock |
| `scripts/` | 安装、开发 shell 和桌面辅助脚本 |
| `.githooks/` | 本仓库使用的 git hooks |
| `.github/workflows/` | CI、缓存构建和依赖更新 workflow |

## Profile 分层

默认 profile 定义在 `lib/vars.nix`：

| Profile | 默认值 | 说明 |
| --- | --- | --- |
| `tuiBase` | 始终启用 | 基础终端工具、语言运行时、Nix LSP / formatter 等 |
| `tuiAdvanced` | `true` | 较重的终端开发工具，例如容器、额外语言工具、Nix 辅助工具 |
| `tuiOptional` | `false` | 可选增强包，例如 Docker Buildx、Clang 和 Linux 上的 Btrfs 工具 |
| `guiBase` | `false` | 基础 GUI 应用和桌面工具 |
| `guiHeavy` | `false` | 更重的 GUI 应用，例如浏览器 |

主机可以在 `flake.nix` 的 `profileLevelOver` 里覆盖这些开关。比如 `buking` 启用完整 GUI profile，`reinsvps` 保持更轻的服务器配置。

## 校验

本地常用校验：

```bash
nix flake check --no-build
nix eval .#homeConfigurations.qi.activationPackage.drvPath --raw
```

GitHub Actions 会执行：

- `nix flake check`
- `statix check .`
- 各 NixOS / nix-darwin / Home Manager 输出的 `nix build --dry-run`

主 CI 会忽略 Markdown、`Justfile`、`.gitignore` 和许可证文件的变更；这些文件单独修改时不会触发 `ci.yml`。

需要手动验证某个输出时，可以直接求值或执行 dry-run：

```bash
nix flake check --no-build
nix build .#nixosConfigurations.buking.config.system.build.toplevel --dry-run
nix build .#darwinConfigurations.handyMini.config.system.build.toplevel --dry-run
nix build .#homeConfigurations.qi.activationPackage --dry-run
```

## Agent Skills

`skills-nix/` 是独立 lock 的 child flake，用
[agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix) 声明、选择并
同步 Agent Skills。它是 Claude、Codex、opencode 的全局 skills 目录和共享
`~/.agents/skills`（omp、pi、dsh 都读它）的唯一写入者；`cc-switch-tui` 需要保持 `skills.mode = "external"`，只管理
provider、MCP 和其他非 Skills 配置。Hermes 的 `$HERMES_HOME/skills` 混合了
bundled skills 与 curator 状态，第一阶段不接管。

技能来自上游仓库：`addyosmani/agent-skills`（21）、`browser-act/skills`（1）和
`TaysiTsuki`（11）；`skills-nix/local/`（35）放没有上游的项目专用技能，以及 5 个
从 Hermes toolkit 复制出来的小工具技能（`NousResearch/hermes-agent` 是 271 MB 的
运行时，没有作为输入引入）。所有技能都部署成扁平的 `<dest>/<name>/SKILL.md`，
因为 DSH 等 agent 只扫描 skills 根目录的一层；`agents` 目标
（`$HOME/.agents/skills`）就是 DSH 读取的那个目录。

```bash
just skills-list      # 当前启用的 68 个技能
just skills-check     # 构建 bundle 并做 flake check
```

选择、上游 source、目标目录在 `skills-nix/catalog.nix`；只有 `hosts` 列出的
主机（`buking`、`handyMini`）会启用目标目录，其它 hosts 与 standalone Home
Manager 不受影响。

来源清单见 `skills-nix/INVENTORY.md`，接管与回滚说明见
`skills-nix/README.md`，设计与偏差记录见 `.github/docs/skills-nix-design.md`。
