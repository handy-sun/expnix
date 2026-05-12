# Code Review: 2026-05-12

Review scope: full codebase audit of `/Users/qi/work/expnix`, covering all `.nix` files
across the flake (flake.nix, lib/, machines/, nixos/, home/, hosts/, modules/).

## Verdict: Request Changes

2 critical issues must be addressed before merging any new code that hits the affected
paths. Remaining findings are minor or informational.

## Follow-up Review: caddy-webdav 修复复核

复核范围：用户针对 Critical/Important 的未提交修复，以及 `.github/workflows`
里的 review/CI gate 设计。

### 修正后的 Critical 结论

原 Critical 1 的描述只覆盖了 Linux activationScript 使用 `staff` 组的问题；进一步验证时发现
问题更严重：`modules/caddy-webdav/default.nix` 如果被导入 NixOS 配置，即使走不到
`activationScripts`，也会因为模块返回值里包含 `launchd` 顶层 option 而求值失败：

```text
error: The option `launchd' does not exist.
```

原因是跨 NixOS/nix-darwin 模块里不能依赖 `lib.mkIf false { launchd = ...; }`
这种形状来隐藏未知 option。Nix module system 仍会看到不属于当前 module system 的顶层
option namespace。

**Preferred fix:** 在模块参数中接收 `options`，用 capability detection 判断后端：

```nix
hasLaunchd = builtins.hasAttr "launchd" options;
hasSystemd = builtins.hasAttr "systemd" options;
```

然后用普通 `if` 选择 `launchd` 或 `systemd` 分支，确保不支持的 option namespace 不会
出现在最终 module value 中。这个模式已经整理成 Codex skill：
`nix-module-capability-detection`。

### 修复状态

- `Caddyfile` basicauth 已改为 Nix 多行字符串，不再输出字面量 `\n`。
- Darwin 分支保留 `launchd.user.agents.caddy-webdav` 和 `chown ${username}:staff`。
- NixOS 分支改为 `systemd.services.caddy-webdav`。
- NixOS activationScript 改为更稳妥的 `chown --reference="${homeDir}" "${cfg.storagePath}"`，
  避免依赖 `config.users.users.${username}.group` 的默认值细节。
- `Justfile` 里的 `preshell` recipe 已删除，而不是只修正无效参数。

### 已执行验证

```bash
nix eval --impure --raw --expr '... cfg.config.system.activationScripts.caddy-webdav.text'
nix eval --impure --raw --expr '... cfg.config.systemd.services.caddy-webdav.serviceConfig.ExecStart'
nix eval --impure --json --expr '... cfg.config.launchd.user.agents.caddy-webdav.serviceConfig.ProgramArguments'
nix fmt -- --ci .
git diff --check
nix flake check --no-build --print-build-logs
```

验证结果：

- NixOS 启用 `caddy-webdav` 后 activation 输出包含
  `chown --reference="/home/qi" "/tmp/webdav"`。
- NixOS `systemd.services.caddy-webdav.serviceConfig.ExecStart` 可求值，不再报 `launchd`
  option 不存在。
- nix-darwin 启用 `caddy-webdav` 后 launchd `ProgramArguments` 可求值。
- `nix flake check --no-build` 在当前 aarch64-darwin 机器通过兼容项；其他系统被 Nix
  标记为 incompatible，没有在本机执行。

---

## Follow-up Review: GitHub workflow

`.github/workflows` 的 CI/review gate 可以接受个人配置仓库的快速反馈需求，但不是严格的
merge gate。需要注意下面几个风险：

### Important: build-cache 的 hash cache 不可靠

**File:** `.github/workflows/build-cache.yml:27-85`

`actions/cache` 的 key 设计为 `build-cache-flake-lock`，但 GitHub Actions cache key
不适合作为可覆盖状态存储。`flake.lock` 更新后，旧 key 通常不会被新 hash 覆盖，后续定时
任务可能持续判断 lock 已变化并反复构建。

**Fix:** 改用包含 lock hash 的 key，例如：

```yaml
key: build-cache-flake-lock-${{ hashFiles('flake.lock') }}
```

然后用 cache hit/miss 判断是否需要构建。

### Important: update-deps 直接 push 到当前分支

**File:** `.github/workflows/update-deps.yml:19-26`

`nix flake update --commit-lock-file` 后直接 `git push`，没有先跑 `nix flake check`，
也不创建 PR。依赖更新如果引入坏 lock，可以直接进入主分支。

**Fix:** 至少在 push 前跑 `nix flake check --no-build`；更稳妥的做法是创建 PR，让
正常 CI/review 流程处理。

### FYI: CI build 只做 dry-run

**File:** `.github/workflows/ci.yml:73`

PR/push build 使用 `nix build ... --dry-run --quiet`，这只能验证求值和 substituter 计划，
不能证明 derivation 实际可构建。对个人 flake 来说这是合理的速度取舍，但不要把它理解为
完整构建验证。

### FYI: paths-ignore 会跳过 Justfile 变更

**File:** `.github/workflows/ci.yml:6-17`

`Justfile` 被 CI 的 `paths-ignore` 排除，所以 `preshell` 这类命令问题不会触发 CI。
如果 Justfile 是常用入口，建议至少保留一个手动或轻量 lint 检查。

---

## Critical

### 1. caddy-webdav activationScripts 在 Linux 上会失败

**File:** `modules/caddy-webdav/default.nix:84-88`

```nix
system.activationScripts.caddy-webdav.text = ''
  mkdir -p ${cfg.storagePath}
  chown ${username}:staff ${cfg.storagePath}
'';
```

`staff` 组是 macOS 特有的。这段代码没有用 `lib.mkIf isDarwin` 保护，如果在 NixOS 上启用
caddy-webdav，`chown` 会因为 `staff` 组不存在而失败。

**Fix:** 用 `lib.mkIf isDarwin` 包裹，或改为 `${if isDarwin then "staff" else "users"}`。

### 2. Caddyfile basicauth 模板使用字面量 `\\n` 而非换行符

**File:** `modules/caddy-webdav/default.nix:27`

```nix
"basicauth {\\n          ${cfg.user} ${cfg.hashedPassword}\\n        }"
```

在 Nix 字符串中，`\\n` 是反斜杠 + n 字面量，不是换行符。生成的 Caddyfile 会是：

```
basicauth {\n          user password\n        }
```

这是**无效的 Caddyfile 语法**，Caddy 启动时会解析失败。

**Fix:** 改用 Nix 多行字符串字面量（`''`）或 Nix 换行转义（`\n`）：

```nix
''
  basicauth {
    ${cfg.user} ${cfg.hashedPassword}
  }
''
```

**注意：** 当前 `handyMini` 的 caddy-webdav 配置未设置 `user`/`hashedPassword`，所以不会
走到这个分支。这是一个等待触发的 bug。

---

## Important

### 3. Justfile `preshell` 命令传了无效参数

**File:** `Justfile:58`

```bash
nix shell 'experimental-features = nix-command flakes' 'nixpkgs#nh' 'nixpkgs#git'
```

第一个参数 `'experimental-features = nix-command flakes'` 不是有效的 `nix shell` 参数。
它看起来是从注释里残留的配置行（上方第 57 行的注释原本是
`# @grep -q 'experimental-features = nix-command flakes' ...`），不应该作为 `nix shell`
的参数传入。运行时会报错。

**Fix:** 删除第一个参数，保留 `nix shell 'nixpkgs#nh' 'nixpkgs#git'`。

---

## Nits

### 4. `lib/vars.nix` 拼写错误

**File:** `lib/vars.nix:7`

```nix
## common system enviroment
```

`enviroment` → `environment`

### 5. `lib/mkhome.nix` 残留注释代码

**File:** `lib/mkhome.nix:45-54`

两套不同的 `pkgs` 配置方案被注释掉了，但当前用的是第 56 行的
`pkgs = nixpkgs.legacyPackages.${system};`。这些注释代码没有保留价值。

### 6. `hosts/reinsvps/services.nix` 函数签名不统一

**File:** `hosts/reinsvps/services.nix:1`

```nix
_: {
```

其他模块都解构了 `specialArgs`（如 `{ lib, pkgs, ... }`）。这里用 `_:` 意味着完全不依赖
外部参数，虽然可行但与项目风格不一致。

### 7. `modules/sing-box/default.nix` systemd 变量转义缺注释

**File:** `modules/sing-box/default.nix:83`

```nix
"${lib.getExe cfg.package} -D ${\"$\"}{STATE_DIRECTORY} -C ${\"$\"}{RUNTIME_DIRECTORY} run"
```

这行是正确的 Nix 转义（输出字面 `${STATE_DIRECTORY}` 给 systemd），但阅读时难以理解。
建议加一行注释解释这是在引用 systemd 的 `RuntimeDirectory=` 和 `StateDirectory=` 路径。

---

## FYI

### 8. `lib/utils.nix` — `scanPaths` 包含目录

**File:** `lib/utils.nix:17`

`(_type == "directory")` 会把子目录也包含到返回列表中。如果 `scanPaths` 扫描的目录下有
子目录（不含 `default.nix`），`import` 会报错。目前没有这种情况，但这是一个潜伏陷阱。

### 9. dae 包无条件安装但服务有条件启用

- `nixos/default.nix:56` 把 `dae` 加入 `environment.systemPackages`
- `nixos/services.nix:22` 用 `enable = mkDefault isHeLinux`

对 WSL 主机（nixwsl），dae 包安装了但服务永远不启用。

### 10. rustdesk-server openFirewall 与显式端口列表重复

`hosts/reinsvps/services.nix:6` 设置了 `openFirewall = true`（自动开放
21115-21119 TCP / 21116 UDP），同时 `hosts/reinsvps/default.nix:43-47` 也显式列出了
这些端口。结果上无害（NixOS 会 dedup），但存在信息冗余。

### 11. dae 和 sing-box 共存关系未文档化

`nixos/services.nix` 中 dae 和 sing-box 都默认启用，但 orbvmnix 显式 `mkForce false`
禁用了 dae。这两个代理工具是否能共存、什么场景下用哪个、为什么 orbvmnix 禁用了 dae，
都没有注释说明。

### 12. reinsvps iptables 规则与 nftables 后端

NixOS 默认使用 nftables 作为防火墙后端。`extraCommands` 中直接操作 `iptables` 命令，
这些命令通过 `iptables-nft` 兼容层操作 nftables 内核 API。虽然能工作，但如果未来
nftables 规则集发生变化，这些 iptables 规则的相对位置和优先级可能不可预测。
