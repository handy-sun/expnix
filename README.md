# expnix

个人 Nix flake 配置仓库，用来统一管理 NixOS、nix-darwin 和 standalone Home Manager 环境。仓库的目标是把系统配置、Home Manager 配置、常用开发工具、图形/终端 profile、私有 dotfiles 输入和 CI 校验放在同一套 flake 工作流里。

## 管理的机器

| 名称 | 类型 | 系统 | 说明 |
| --- | --- | --- | --- |
| `orbvmnix` | NixOS | `aarch64-linux` | OrbStack / 虚拟化 Linux 环境，启用 `tuiOptional` |
| `reinsvps` | NixOS | `x86_64-linux` | VPS / 服务器环境 |
| `nixwsl` | NixOS-WSL | `x86_64-linux` | WSL2 环境，启用 `tuiOptional` 和 `guiBase` |
| `buking` | NixOS | `x86_64-linux` | 物理 Linux 桌面环境，启用完整 GUI profile |
| `handyMini` | nix-darwin | `aarch64-darwin` | macOS 环境，启用 `tuiOptional` 和 `guiBase` |
| `qi` | Home Manager | `x86_64-linux` | standalone Home Manager 配置 |

## 首次引导

所有命令默认在仓库根目录执行。

首次进入开发 shell：

```bash
nix develop
```

仓库在 `flake.nix` 顶层声明了 `nixConfig.bash-prompt`，进入 `nix develop` 后会直接使用项目定义的 bash prompt。系统侧配置里也默认开启了 `accept-flake-config = true`，因此会自动接受该 flake 暴露的 Nix 配置。

开发 shell 会提供 `git`、`just`、`nh`、`statix` 等仓库维护需要的工具。进入后建议先安装本仓库的 git hook：

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

## 常用命令

| 命令 | 说明 |
| --- | --- |
| `just` | 查看所有可用 recipe |
| `just setup-hook` | 设置 `.githooks` 为当前仓库的 git hooks 目录 |
| `just switch` | 激活当前机器的 NixOS 或 nix-darwin 配置 |
| `just switch-home` | 只激活 Home Manager 配置 |
| `nix fmt` | 推荐的 Nix 格式化入口，使用 flake 暴露的 treefmt wrapper |
| `just nixfmt` | 旧格式化入口，直接对 `.nix` 文件运行 `nixfmt`，保留作兼容用途 |
| `just repl` | 打开当前 flake 的 `nix repl` |
| `just repl-nh` | 打开当前系统的 `nh os repl` 或 `nh darwin repl` |
| `just history` | 查看系统 profile 历史 |
| `just gc` | 清理 4 天前的未使用 Nix store 条目 |

## 更新流程

仓库把不同来源的 flake input 分成几类更新，便于减少不相关变更混在一起：

| 命令 | 更新范围 |
| --- | --- |
| `just upc-nix` | 更新 Nix 生态相关输入，并自动提交 `flake.lock` |
| `just upc-llm` | 更新 `llm-agents`，并自动提交 `flake.lock` |
| `just upc-my` | 更新个人 dotfiles / 脚本类输入，并自动提交 `flake.lock` |
| `just up-my` | 更新个人 dotfiles / 脚本类输入，但不自动提交 |

CI 里也有每周自动更新依赖的 workflow，会执行完整的 `nix flake update --commit-lock-file` 并推送结果。

## 格式化和提交检查

当前项目标准格式化入口是：

```bash
nix fmt
```

`flake.nix` 通过 `treefmt-nix` 暴露 formatter，并把 `Mic92/nixfmt-rs` 的预编译 release 二进制作为项目格式化器使用；不会引入 `nixfmt-rs` flake input，也不会因为 input 更新反复源码构建。`.githooks/pre-commit` 会对 staged 的 `.nix` 文件运行：

```bash
nix fmt -- --fail-on-change <staged-nix-files>
```

如果 hook 失败，先运行 `nix fmt`，重新 `git add` 格式化后的文件，再提交。

系统包列表和编辑器配置里的 `pkgs.nixfmt` 仍保持官方实现；项目级格式化以 `nix fmt` 为准，实际调用预编译的 `nixfmt-rs`。

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
| `.githooks/` | 本仓库使用的 git hooks |
| `.github/workflows/` | CI、缓存构建和依赖更新 workflow |

## Profile 分层

默认 profile 定义在 `lib/vars.nix`：

| Profile | 默认值 | 说明 |
| --- | --- | --- |
| `tuiBase` | 始终启用 | 基础终端工具、语言运行时、Nix LSP / formatter 等 |
| `tuiAdvanced` | `true` | 较重的终端开发工具，例如容器、额外语言工具、Nix 辅助工具 |
| `tuiOptional` | `false` | 可选增强包，例如 Rust toolchain 和 `llm-agents` 提供的 agent 工具 |
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

Markdown、`Justfile`、`.gitignore` 和许可证文件的变更不会触发主 CI。
