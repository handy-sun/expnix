# expnix 的 System Manager 分析

## 对 expnix 的适配判断

expnix 目前有三类主要输出：

```text
nixosConfigurations   -> 完整 NixOS 系统
darwinConfigurations  -> nix-darwin 系统
homeConfigurations    -> standalone Home Manager
```

建议新增第四类输出：

```text
systemConfigs         -> 非 NixOS Linux，通过 system-manager + Home Manager 管理
```

这不应该替代 `homeConfigurations`，而应该与它并列。

### 为什么不要直接塞进 `mkhome.nix`

当前 `lib/mkhome.nix` 返回：

```nix
inputs.home-manager.lib.homeManagerConfiguration { ... }
```

它适合用于：

```nix
homeConfigurations.${user}
```

System Manager 返回的是另一种对象：

```nix
system-manager.lib.makeSystemConfig { ... }
```

它应该放在：

```nix
systemConfigs.<host>
```

把两种返回类型塞到同一个 `mkHome` 函数里，会让 flake 更难读，也更容易误用。
像 `useSystemManager ? false` 这样的参数会让函数形状取决于运行时意图，而不是名字。

更干净的做法是：

```text
lib/mkhome.nix      -> standalone Home Manager
lib/mksystem.nix    -> NixOS / nix-darwin
lib/mksysmgr.nix    -> system-manager + Home Manager
```

名字可以调整，但单独的 constructor 才是重点。

### 可以复用什么

应该复用：

- `../home`
- `profileLevel`
- `myvars`
- `myutils`
- `inputs`
- `username`
- `homeDir`
- `overlays/rldd.nix` 这类 overlays
- `home/` 下大多数 Home Manager modules

应该为 system-manager 重新建模：

- host-level users/groups
- system-manager host modules
- 对非 NixOS 安全的 service definitions
- `/etc` 文件
- systemd services 和 timers
- Nix daemon settings

### 不应该盲目复用什么

不要整体导入现有完整 NixOS host modules，尤其是：

- `hosts/reinsvps/default.nix`
- `hosts/buking/default.nix`
- `hosts/*/hardware-configuration.nix`
- `machines/nix-core.nix`
- `nixos/default.nix`

这些模块包含在 NixOS 上有意义、但在 system-manager 下不一定有意义的 options：

- `boot.*`
- `fileSystems.*`
- `swapDevices`
- `hardware.*`
- `networking.networkmanager.*`
- `networking.firewall.extraCommands`
- `services.pipewire.*`
- `services.greetd.*`
- display stack 和 desktop services

其中一些可能靠 stubs 通过求值，但能求值不等于能安全管理宿主。

## 建议的 expnix Constructor 形状

未来的 `lib/mksysmgr.nix` 可以采用这个形状：

```nix
{
  nixpkgs,
  inputs,
  myvars,
  myutils,
}:

hostName:
{
  system,
  username ? "${myvars.user}",
  isWSL ? false,
  profileLevelOver ? { },
  allowAnyDistro ? false,
  extraModules ? [ ],
}:

let
  profileLevel = myvars.profileLevel // profileLevelOver;
  isDarwin = false;
  isHmSingle = false;
  isHeLinux = !isWSL;
  homeDir = if username == "root" then "/root" else "/home/${username}";
  specialArgs = {
    inherit
      inputs
      hostName
      username
      myvars
      myutils
      homeDir
      isDarwin
      isWSL
      isHeLinux
      isHmSingle
      profileLevel
      ;
  };
in
inputs.system-manager.lib.makeSystemConfig {
  specialArgs = specialArgs;

  overlays =
    (import ../overlays/rldd.nix { inherit (nixpkgs) lib; }).nixpkgs.overlays;

  modules = [
    inputs.home-manager.nixosModules.home-manager
    {
      nixpkgs.hostPlatform = system;
      nixpkgs.config.allowUnfree = true;

      system-manager.allowAnyDistro = allowAnyDistro;

      nix.enable = true;
      services.userborn.enable = true;

      users.groups.${username} = { };
      users.users.${username} = {
        isNormalUser = true;
        group = username;
        home = homeDir;
        createHome = true;
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = import ../home;
        extraSpecialArgs = specialArgs;
      };
    }
  ] ++ extraModules;
}
```

这只是示意。如果实现，需要按真实 `flake.nix` 结构调整，并用 `nix eval` 和
`nix build` 验证。

## 重要的 nixpkgs pin 细节

在 expnix 中使用 system-manager 时，建议配置：

```nix
system-manager = {
  url = "github:numtide/system-manager";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

这很重要，因为 Home Manager modules 和 expnix 的包列表都假定使用 flake pin 住的
nixpkgs。调研中发现，如果直接使用 system-manager 自己 pin 的 nixpkgs，可能遇到包名
差异，例如某些包存在于 expnix 的 nixpkgs，但不存在于上游 system-manager 的 pin。

system-manager constructor 应尽量使用与 expnix 其他部分相同的 nixpkgs 和 overlays。

## 调研期间做过的 Smoke Test

调研期间做过一个本地 eval-only smoke test，没有向 repo 添加文件，也没有激活
system-manager。

测试把现有 `../home` Home Manager module 嵌入到
`system-manager.lib.makeSystemConfig`，并使用 expnix 的 nixpkgs pin 和 `rldd`
overlay。

结果确认：

- 生成的 systemd units 中存在 `home-manager-qi.service`
- `nix.enable = true`
- `services.userborn.enable = true`
- Home Manager 可以生成 `.config/npmrc`
- `home.packages` 可以成功求值，共 140 个包

这说明整体架构可行。它不证明每个包都能构建，也不证明在真实主机上激活一定安全。

## 候选迁移策略

### Phase 1: 添加 input 和 constructor

添加 `system-manager` flake input，并让它 follow `nixpkgs`。

新增一个 constructor，例如：

```text
lib/mksysmgr.nix
```

不要修改 `mkhome.nix`，让它返回两种不同输出类型。

### Phase 2: 添加最小非 NixOS host

添加一个小的 host module，例如：

```text
hosts/<non-nixos-host>/system-manager.nix
```

一开始只包含：

- `nixpkgs.hostPlatform`
- `nix.enable`
- `services.userborn.enable`
- 主用户和用户组
- Home Manager import
- 少量系统包
- 一个无害的 `/etc` 测试文件或 systemd oneshot

这个阶段不要导入完整 `nixos/` tree。

### Phase 3: 选择性迁移服务

好的候选：

- `beszel-agent`
- `frpc`
- `webdav`
- 简单 Caddy/nginx services
- 自定义 oneshot/timer units
- 服务专用 `/etc` 文件

风险更高的候选：

- sing-box/dae，如果它们依赖宿主 networking、dbus、firewall、tun，或不同发行版差异较大的
  service capabilities
- 桌面服务
- 任何要求 PAM、udev、display-manager、kernel modules 或 firewall ownership 的内容

### Phase 4: 构建和激活验证

先做求值：

```bash
nix eval .#systemConfigs.<host>.config.systemd.units --json
nix build .#systemConfigs.<host>
```

然后在一次性或可恢复的机器上部署：

```bash
nix run github:numtide/system-manager -- switch --flake .#<host> --sudo
```

远程主机：

```bash
nix run github:numtide/system-manager -- \
  --target-host user@host \
  switch \
  --flake .#<host> \
  --sudo
```

远程部署前，远端 Nix daemon 必须信任部署用户，或接受复制过去的 closures。
上游文档特别提到要在 `/etc/nix/nix.conf` 中设置 `trusted-users` 和
`build-users-group`。

## 运维注意事项

### 激活安全

System Manager 会追踪受管的 `/etc` 文件，避免触碰配置范围之外的路径。但是，一旦
使用 `replaceExisting = true`，它就会接管那个路径。只有在已有宿主配置已经被表达进
Nix 后，才应该使用它。

### 回滚

CLI 文档指出，直接 rollback 的 UX 仍然有限，但 generations 可以通过 `nix-env` 操作：

```bash
sudo nix-env --profile /nix/var/nix/profiles/system-manager-profiles --list-generations
sudo nix-env --profile /nix/var/nix/profiles/system-manager-profiles --rollback
nix run 'github:numtide/system-manager' -- activate --sudo
```

这不如 NixOS rollback 集成完整，而且不会回滚 kernel、bootloader 或基础发行版状态。

### PATH 和环境变量

`environment.variables` 通过 `/etc/profile.d/system-manager-path.sh` 导出。
这对登录 shell 环境是合适的。

`environment.sessionVariables` 也存在，但上游说明 system-manager 不管理宿主 PAM。
因此这些变量不会像 NixOS 那样通过 PAM 注入到所有非 shell session 中。

实际影响：

- CLI/server 环境很适合。
- GUI session 和 PAM-mediated 环境可能需要发行版原生配置。

### Firewall

System Manager 包含 firewall option 兼容层，因此导入的 NixOS modules 设置
`networking.firewall.allowedTCPPorts` 时可以求值，但它不拥有宿主防火墙。
除非专门写自定义 systemd service，否则宿主发行版防火墙仍应由发行版原生机制管理。

### Sops

System Manager 为 `sops-nix` activation scripts 提供兼容 stubs，并且上游有使用 SSH
host keys 解密 secrets 的测试。这可以工作，但由于 secret activation 与 NixOS 不同，
生产环境依赖前应仔细验证。

## 决策建议

可以在非 NixOS Linux 主机上使用 system-manager，但应把它作为 expnix 中单独的一类
target：

```text
nixosConfigurations   -> 真 NixOS
darwinConfigurations  -> nix-darwin
homeConfigurations    -> standalone Home Manager
systemConfigs         -> system-manager + Home Manager
```

不要试图让非 NixOS Linux 看起来完全等同于 NixOS。更合理的是定义一个可移植子集：

- Home Manager 管用户空间
- system-manager 管 systemd、`/etc`、系统包、Nix 设置和用户
- 发行版包管理器和原生配置继续负责 boot、kernel、hardware、filesystems、
  networking/firewall 基础策略和桌面集成

这样可以为服务器和开发机获得大部分有用的 NixOS-style 声明式工作流，同时不假装拥有
system-manager 明确留给发行版的 OS 部分。
