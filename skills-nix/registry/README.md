# registry/

用 manifest 加一份生成的 lock 固定上游 skills 仓库，避免为每个仓库新增一个
flake input。

```text
registry/
├── sources/<name>.nix   # 人工维护的 manifest
└── sources.lock.json     # 生成物：归一化 manifest + npins pins
```

manifest 形状：

```nix
{
  pin = {
    type = "github";
    owner = "anthropics";
    repo = "skills";
    branch = "main";
  };

  subdir = "skills";
  idPrefix = "anthropic";
  filter.maxDepth = 2;
}
```

在本目录刷新 lock，然后审查 manifest 与生成差异，最后才切换：

```bash
cd skills-nix
nix run .#skills-sources-lock
nix flake check .
```

registry 生成的 sources 与 `sources.local` 用法一致；lock 提交后再加入
`catalog.nix`。registry lock 与 `flake.lock` 是两层锁：改 manifest 要重新生成
registry lock，改 flake input 要用 `nix flake update`。

目前没有提交任何 manifest。第一个上游 skill 应当连同 manifest 和 lock 一起
进入，符合迁移计划的分阶段提交。
