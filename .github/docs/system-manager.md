# System Manager 分析

范围：记录围绕在非 NixOS Linux 主机上使用 `numtide/system-manager` 与
Home Manager 组合的调研结论。

主要上游来源：

- <https://github.com/numtide/system-manager>
- <https://system-manager.net/main/>
- <https://system-manager.net/main/explanation/how-it-works/>
- <https://system-manager.net/main/explanation/nixos-comparison/>
- <https://system-manager.net/main/reference/modules/>
- <https://system-manager.net/main/reference/supported-platforms/>
- <https://system-manager.net/main/examples/home-manager/>
- <https://system-manager.net/main/how-to/import-nixos-module/>
- <https://system-manager.net/main/how-to/deploy-remotely/>
- <https://system-manager.net/main/how-to/rollback/>

本次讨论中检查的上游快照是：

```text
numtide/system-manager dc1baae12eed1758755e73f8aff7fca5502c6e9f
```

## 问题背景

对于非 NixOS 的 Linux 发行版，单独使用 Home Manager 很有用，但它的作用域
太偏用户级。它可以管理 dotfiles、用户包、shell、编辑器以及很多用户级
程序，但不能接管系统级服务、`/etc`、系统用户、系统包或全局 Nix 设置。

目标是评估 `system-manager` 能否补上这块系统级能力，同时继续复用 expnix
现有的 Home Manager 配置。

目标使用场景是：

- 非 NixOS Linux 主机
- 已经安装 Nix
- bootloader、kernel、initrd、硬件和文件系统仍由宿主发行版管理
- Nix 管理这条边界之上的可复现部分：服务、包、系统环境、用户和用户配置

## System Manager 是什么

`system-manager` 是一个只面向 Linux 的系统配置工具，基于 Nix 和 Nix module
system 构建。它给其他 Linux 发行版带来类似 NixOS 的配置体验，但刻意只控制
比 NixOS 更小的系统表面。

比较准确的理解是：

```text
NixOS module 风格的配置
+ Nix store 构建
+ 特权激活
+ systemd 和 /etc 管理
- boot/kernel/filesystem 所有权
```

它不是一个完整发行版，也不会替代 Ubuntu、Debian、Fedora、Arch 或宿主包管理器。
它与宿主发行版共存。

上游文档描述了两个主要阶段：

1. 构建阶段：求值 Nix modules，并把包、service 文件和 `/etc` 条目构建进
   Nix store。
2. 激活阶段：带权限注册一个 generation，更新受管的 `/etc` 文件，安装 systemd
   units，启动、停止或重启变更的服务，并安装 system-manager PATH 的 profile
   脚本。

成功激活后会在这里注册 generations：

```text
/nix/var/nix/profiles/system-manager-profiles/
```

## 它能管理什么

System Manager 可以管理那些仅靠 Home Manager 通常很难表达的系统级部分。

### 系统包

使用：

```nix
environment.systemPackages = with pkgs; [
  btop
  ripgrep
  nginx
];
```

这些包会通过下面的路径暴露：

```text
/run/system-manager/sw/bin
```

首次激活时，system-manager 会创建：

```text
/etc/profile.d/system-manager-path.sh
```

这个脚本会把 `/run/system-manager/sw/bin` 加到登录 shell 的 PATH 中；如果存在
用户 profile，也会加入：

```text
/etc/profiles/per-user/$USER/bin
```

### `/etc` 文件

使用：

```nix
environment.etc."myapp/config.toml" = {
  text = ''
    key = "value"
  '';
  mode = "0644";
};
```

支持的字段包括：

- `enable`
- `target`
- `text`
- `source`
- `mode`
- `uid`
- `gid`
- `user`
- `group`
- `replaceExisting`

接管宿主机上已经存在的文件时，`replaceExisting = true` 很重要。System Manager
会把已有文件备份到：

```text
<path>.system-manager-backup
```

当条目被移除或 system-manager 被 deactivate 时，它可以恢复这个备份。

### systemd units

System Manager 对 systemd unit 定义有一等支持：

- `systemd.services`
- `systemd.timers`
- `systemd.sockets`
- `systemd.targets`
- `systemd.paths`
- `systemd.mounts`
- `systemd.automounts`
- `systemd.slices`
- `systemd.generators`
- `systemd.shutdown`
- `systemd.maskedUnits`
- `systemd.packages`

示例形状：

```nix
systemd.services.myapp = {
  enable = true;
  description = "My application";
  wantedBy = [ "system-manager.target" ];
  after = [ "network-online.target" ];
  wants = [ "network-online.target" ];
  serviceConfig = {
    Type = "simple";
    ExecStart = "${pkgs.myapp}/bin/myapp";
    Restart = "on-failure";
  };
};
```

为了兼容 NixOS module，system-manager 会在 unit 生成阶段把 `wantedBy` 和
`requiredBy` 里的 `multi-user.target` 重写成 `system-manager.target`。

### tmpfiles

使用：

```nix
systemd.tmpfiles.rules = [
  "d /var/lib/my-service 0755 root root -"
];
```

或者：

```nix
systemd.tmpfiles.settings."10-my-service" = {
  "/var/lib/my-service".d = {
    mode = "0755";
    user = "root";
    group = "root";
  };
};
```

这适合管理状态目录、socket、运行时路径，以及需要可预测创建的目录。

### 用户和组

System Manager 可以通过 `users.users` 和 `users.groups` 声明用户和组。当前上游
实现使用 `userborn`。

示例：

```nix
users.groups.myapp = { };

users.users.myapp = {
  isSystemUser = true;
  group = "myapp";
  home = "/var/lib/myapp";
  createHome = true;
  description = "My application service account";
};
```

交互式用户示例：

```nix
users.groups.qi = { };

users.users.qi = {
  isNormalUser = true;
  group = "qi";
  home = "/home/qi";
  createHome = true;
  extraGroups = [
    "wheel"
    "docker"
  ];
};
```

它也提供密码相关选项，包括 `initialPassword`、`initialHashedPassword`、
`hashedPassword` 和 `hashedPasswordFile`。对于 mutable users 设置，initial
password 选项只在首次创建用户时应用。

### Nix 配置

System Manager 包含一个较小的 Nix module 兼容层：

```nix
nix.enable = true;
nix.settings.experimental-features = [
  "nix-command"
  "flakes"
];
```

当 `nix.enable = true` 时，它会通过 `environment.etc."nix/nix.conf"` 管理
`/etc/nix/nix.conf`，并设置 `replaceExisting = true`。

这很有用，但也是一个接管点。允许 system-manager 拥有 `nix.conf` 之前，已有宿主
设置必须先完整表达进 Nix。

### Home Manager 集成

上游官方文档包含 Home Manager 示例。模式是：

```nix
systemConfigs.default = system-manager.lib.makeSystemConfig {
  modules = [
    home-manager.nixosModules.home-manager
    ({ pkgs, ... }: {
      nixpkgs.hostPlatform = "x86_64-linux";

      services.userborn.enable = true;
      nix.enable = true;

      users.groups.alice.gid = 5000;
      users.users.alice = {
        isNormalUser = true;
        uid = 5000;
        group = "alice";
        home = "/home/alice";
        createHome = true;
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
        users.alice = { pkgs, ... }: {
          home.stateVersion = "25.11";
          home.packages = [ pkgs.ripgrep ];
          programs.git.enable = true;
        };
      };
    })
  ];
};
```

激活时会创建类似这样的用户级服务：

```text
home-manager-alice.service
```

设置 `useUserPackages = true` 后，Home Manager 用户包会安装到：

```text
/etc/profiles/per-user/<username>/bin
```

并通过 system-manager 的 profile 脚本进入登录 shell PATH。

## 它不管理什么

System Manager 刻意不管理：

- bootloader
- kernel
- initrd
- 完整硬件栈
- root 文件系统和分区
- `/etc` 之外的任意文件
- 非 systemd init system
- macOS 或 BSD

它也不能完整替代宿主发行版在这些集成点上的职责：

- PAM
- SELinux/AppArmor policy
- desktop display manager
- 底层网络栈
- 完整防火墙所有权
- udev 和硬件相关服务

有些 NixOS 选项只是 stub 或兼容 shim。这是关键区别：一个选项可能能求值，
但背后的行为仍然可能由宿主发行版负责。

## 支持平台和要求

官方文档列出的平台支持：

- Ubuntu 22.04+
- Ubuntu on WSL2
- Debian 13
- Fedora 和 Arch 被描述为 community/should-work 平台

System Manager 要求：

- 使用 systemd 的 Linux
- system-wide multi-user Nix 安装
- flakes 已启用
- 足够的磁盘和内存来跑 Nix 构建

默认情况下，激活会检查 `/etc/os-release`，只允许：

- `nixos`
- `ubuntu`
- `debian`

其他发行版需要设置：

```nix
system-manager.allowAnyDistro = true;
```

这会完全关闭检查。它不是选择性 allowlist，应该理解成“风险自担”，而不是等价的官方支持。

## NixOS 覆盖率估计

只要明确排除 boot、kernel、hardware、filesystem 和深度桌面栈
集成，Home Manager 加 System Manager 大约可以覆盖日常服务器或开发机上 70-85% 的
NixOS 实用体验。

这个估计说的是实际用例，不是 option 数量。

| 领域 | 覆盖度 | 说明 |
| --- | --- | --- |
| systemd services/timers/sockets | 高 | system-manager 的核心强项之一。 |
| 系统包 | 高 | `environment.systemPackages` 很自然地映射到 `/run/system-manager/sw`。 |
| `/etc` 文件 | 高 | `environment.etc` 是核心受管表面。 |
| 用户 dotfiles 和包 | 很高 | Home Manager 仍然是正确工具。 |
| 用户和组 | 中高 | 通过 userborn 工作；适合声明式用户和服务账号。 |
| Nix daemon 配置 | 中高 | 有 `nix.enable` 和 `nix.settings`，但会接管 `/etc/nix/nix.conf`。 |
| 系统环境变量 | 中 | 登录 shell 覆盖较好；GUI/PAM/非 shell session 不如 NixOS 完整。 |
| 复用 NixOS modules | 中 | 最适合主要生成 packages、`/etc` 和 systemd units 的模块。 |
| 防火墙/网络栈 | 低中 | 有些选项为兼容可接受，但宿主发行版仍负责实际行为。 |
| 桌面栈 | 低中 | 可以做部分服务，但不现实地接管完整 NixOS 桌面体验。 |
| boot/kernel/filesystems | 不在范围内 | 必须继续由发行版管理。 |

有用的判断规则：

```text
如果一个模块主要生成 packages、/etc 文件、用户和 systemd units，
它就是 system-manager 的好候选。

如果它依赖 kernel、boot、PAM、udev、NixOS activation scripts、hardware，
或全局发行版集成，就要预期需要 stubs、重写，甚至应直接放弃。
```

## 现有上游 module 兼容性

System Manager 包含自己的原生模块，以及一组经过筛选和适配的 NixOS modules。
本次检查的上游树里包含这些模块或兼容层：

- `environment.*`
- `environment.etc`
- `systemd.*`
- `systemd.tmpfiles`
- `system.autoUpgrade`
- `nix.*`
- `users.*`
- `services.userborn`
- `services.nginx`
- ACME/dhparams
- `services.openssh`
- `programs.ssh`
- `security.sudo`
- `security.wrappers`
- `sops-nix` 兼容 stubs
- firewall option stubs

上游文档说明了导入额外 NixOS modules 的技术：

```nix
{ nixosModulesPath, ... }:
{
  imports = [
    (nixosModulesPath + "/services/system/saslauthd.nix")
  ];
}
```

如果被导入模块引用了 NixOS-only options，就只为这些 options 定义 stubs。例如：

```nix
{ lib, ... }:
{
  options.boot = lib.mkOption {
    type = lib.types.raw;
  };
}
```

这个方法应该保守使用。如果一个模块需要大量 stubs，它通常不是好的移植候选。
