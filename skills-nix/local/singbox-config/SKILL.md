---
name: singbox-config
description: "Generate, modify, and debug sing-box client configuration files (v1.12+). Covers TUN and system proxy modes for end-user devices (SFM/SFA/SFI/CLI). Does NOT cover server-side setup (proxy server inbound listeners). Use this skill whenever the user mentions sing-box, singbox, SFM, SFA, SFI, TUN/system proxy setup, split routing, rule-set based routing, or asks to create/modify/fix a client config. Also trigger when the user wants specific domains or common foreign sites to always go proxy/direct, needs Clash/V2Ray nodes converted to sing-box (VLESS, VMess, Shadowsocks, Trojan, Hysteria2, TUIC, ShadowTLS, AnyTLS), or is debugging DNS hijack, fakeip, selector, rule-set download, or connectivity issues. Also covers advanced client features: multiplex/mux, TLS fragment (anti-DPI), ECH, proxy chaining (detour), WireGuard endpoints, per-app routing (Android), network strategy (mobile WiFi/cellular), and WiFi SSID-based routing."
---

# sing-box 客户端配置生成器

生成适用于中国用户的生产级 sing-box **客户端**配置（v1.12+），包含分流路由。本 skill 编码了大量实战经验，避免因配置错误导致网络完全瘫痪。

**覆盖范围：** 客户端（连接到代理服务器的终端设备）— TUN 模式、系统代理模式、SFM/SFA/SFI 图形客户端、命令行 `sing-box run`。
**不覆盖：** 服务端配置（搭建代理服务器），包括 shadowsocks/vmess/vless/trojan/hysteria2 等协议的 inbound 监听、服务端 TLS（ACME、Reality server）、透明代理网关（tproxy/redirect）。如果用户询问服务端配置，请告知此 skill 仅覆盖客户端，建议参考官方文档 https://sing-box.sagernet.org/configuration/inbound/ 。

## 参考资料

- `references/cookbook.md` — **优先阅读。** 解释 sing-box 各组件的实际工作原理：连接生命周期、DNS 查询流程、FakeIP 完整生命周期、规则匹配逻辑、常见配置模式和陷阱。还包含高级模式：代理链（detour）、多路复用（multiplex）、TLS 分片、分应用代理、网络策略、WiFi SSID 路由、ECH。
- `references/config-schema.md` — 完整配置字段参考：所有 DNS 服务器类型、规则匹配字段、路由动作、所有出站类型（含 hysteria2/tuic/shadowtls/anytls）、WireGuard endpoint、TUN 选项、TLS 选项（ECH/uTLS/Reality/Fragment）、multiplex、UDP over TCP、V2Ray transport、NTP、Certificate。
- `references/template.json` — 生产级模板配置。生成新配置时以此为起点。
- **官方文档**: https://sing-box.sagernet.org/configuration/ — 当用户询问的功能在上述参考中未涉及时，使用 WebFetch 获取。
- **源码验证（最后手段）**: 当文档和 cookbook 都无法确定某个配置字段的确切行为时，直接阅读 sing-box 源码。仓库地址 `https://github.com/sagernet/sing-box`，如果用户本地有仓库则直接读取。源码是唯一权威来源 — 文档可能过时或不完整。详见下方"源码验证指南"。

## 关键规则

违反以下任何一条都会导致网络完全瘫痪或启动崩溃。

### 1. DNS 劫持：必须先 sniff，再用逻辑 OR

路由规则的前两条必须是：

```json
{ "action": "sniff" },
{
  "type": "logical", "mode": "or",
  "rules": [{ "protocol": "dns" }, { "port": 53 }],
  "action": "hijack-dns"
}
```

原因：不先 `sniff`，协议检测尚未运行。若仅用 `"protocol": "dns"`，UDP DNS 包会先命中 `ip_is_private`（TUN 网关 `172.19.0.2` 是私有地址）→ 发往不存在的地址 → 全部 DNS 失败 → 全网瘫痪。逻辑 OR 结合 protocol + port 53 可以捕获所有 DNS。

### 2. v1.13 已移除（会启动崩溃）

- `"type": "dns"` outbound → 改用 `"action": "hijack-dns"` 路由规则
- `"type": "block"` outbound → 改用 `"action": "reject"` 路由规则
- `"outbound": "any"` DNS 规则 → 改用 outbound 的 `domain_resolver` 或 route 的 `default_domain_resolver`

### 3. 已弃用（产生警告，v1.14 将移除）

- inbound 上的 `"sniff": true` → 改用 `"action": "sniff"` 作为首条路由规则
- 旧版 DNS `"address"` 字段 → 改用 `"type"` + `"server"` 字段

### 4. IPv6：默认 ipv4_only + 不配 TUN IPv6 地址

除非用户确认 IPv6 可用，否则设置 `"strategy": "ipv4_only"`。国内家庭宽带普遍缺乏 IPv6 路由 → 所有 AAAA 结果都会 `no route to host`。

**关键：除非确认 IPv6 可用，否则不要给 TUN inbound 配 IPv6 地址。** 当前版本 sing-tun 已确保不配 IPv6 地址时不会添加 IPv6 路由（`BuildAutoRouteRanges` 中有 `len(Inet6Address) > 0` 守卫）。默认仅 IPv4：

```json
"address": "172.19.0.1/30"
```

不要在 IPv6 不通的网络上使用 `"address": ["172.19.0.1/30", "fdfe:dcba:9876::1/126"]`。

**原因：** TUN 配了 IPv6 地址后，会在系统中创建 IPv6 路由，导致应用认为 IPv6 可用。微信等应用使用 HTTPDNS（基于 HTTP 的域名解析，完全绕过 sing-box 的 DNS 模块）获取 IPv6 地址，然后直接连接原始 IPv6 IP。这些连接进入 TUN → 路由到 direct outbound → 在真实网卡上连接失败（`no route to host`）。由于应用看到了有效的 IPv6 路由（指向 TUN），它会持续重试 IPv6 而不通过 Happy Eyeballs 回退到 IPv4。移除 TUN 的 IPv6 地址后，系统没有 IPv6 路由 → 应用立即回退 IPv4 → 一切正常。

**注意：** 仅设置 `dns.strategy: "ipv4_only"` 无法解决此问题。HTTPDNS 的响应在 HTTP 载荷内部，不是 DNS AAAA 记录 — sing-box 的 DNS 模块根本看不到。

**IPv6 兼容性矩阵：**

| 网络环境 | TUN 地址 | 行为 |
|---------|---------|------|
| 仅 IPv4 | 仅 IPv4 | 所有流量经 TUN，应用原生回退 IPv4 |
| IPv4 + IPv6 | 仅 IPv4 | IPv4 经 TUN（代理/规则），IPv6 绕过 TUN（真实网卡直连） |
| IPv4 + IPv6 | IPv4 + IPv6 | 所有流量经 TUN，sing-box 完全控制 |

经常在不同网络间切换的用户，**仅 IPv4 TUN** 是最安全的通用默认值。代价：在 IPv6 网络上，IPv6 流量绕过 sing-box（不被代理、不被规则匹配）。这可以接受，因为国内 IPv6 直连本来就是最优路径，而需代理的域名使用 fakeip（仅 IPv4）→ 始终进入 TUN。

### 5. 规则集 URL：使用 jsdelivr CDN

`raw.githubusercontent.com` 在国内被墙。使用：
```
https://testingcf.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-{name}.srs
https://testingcf.jsdelivr.net/gh/SagerNet/sing-geoip@rule-set/geoip-{code}.srs
```
`@cn` 变体标签（如 `geosite-apple-cn`）→ URL 文件名使用 `@`：`geosite-apple@cn.srs`。
备用 CDN：`fastly.jsdelivr.net`。

### 6. 防泄漏规则

在 `ip_is_private` 规则之后，拒绝 DoT 和 STUN 以防止 DNS 泄漏：
```json
{
  "type": "logical", "mode": "or",
  "rules": [{ "port": 853 }, { "protocol": "stun" }],
  "action": "reject"
}
```

不要全局拒绝 UDP 443（QUIC）— 这会导致微信发图失败以及其他使用 QUIC 连接国内服务器的应用异常。防泄漏规则在国内直连规则之前运行，国内 QUIC 流量会在匹配 geosite-cn 之前被杀掉。

## 架构

```
DNS 规则（按顺序匹配）：
  hosts 服务器       → 系统 hosts 文件（最高优先级，ip_accept_any fallthrough）
  自定义直连域名     → local-dns 或 alidns（绕过 fakeip，获取真实 IP）
  自定义代理域名     → 通常不需要 DNS 规则（落入 fakeip 兜底即可）
  clash_mode         → Direct 用 local-dns，Global 用 google-dns
  广告               → reject（阻止 DNS 解析）
  国内域名           → alidns 223.5.5.5（geosite-cn + @cn 变体，真实 IP）
  其他 A/AAAA       → fakeip（海外域名、未分类域名全部获得 fakeip）
  final              → google DoH 经代理（仅处理 MX/TXT/SRV 等非 A/AAAA 查询）

路由（顺序很重要）：
  1. sniff
  2. hijack-dns（port 53 OR protocol dns）
  3. ip_is_private → direct
  4. 防泄漏（拒绝 DoT/STUN — 不拒绝 QUIC）
  5. 自定义 domain_suffix → direct / proxy
  6. clash_mode（Direct/Global）
  7. 广告 → reject
  8. 分服务选择器（AI/Google/Microsoft/Apple/Steam/Telegram）
  9. 常见海外域名 → geosite-geolocation-!cn → proxy
  10. geosite-cn + geoip-cn → direct
  11. final → proxy
```

## FakeIP 解析生命周期（源码验证）

理解此流程对调试 DNS 问题至关重要。已通过 sing-box 源码验证。

```
1. 应用查询 DNS: example.com → A?
2. DNS 规则匹配 → fakeip-dns
3. FakeIP transport 返回假 IP（如 198.18.x.x），不做任何真实 DNS 查询
   （store.go: Store.Create() 从 inet4_range 分配，存储双向映射）
4. 应用连接 198.18.x.x:443
5. 路由器拦截（route.go: matchRule()）：
   - 通过 Store.Contains() 检测目标在 fakeip 范围内
   - 反查：198.18.x.x → "example.com"（Store.Lookup()）
   - 用 FQDN 替换目标地址，设置 metadata.FakeIP = true
   - 将假 IP 保存到 metadata.OriginDestination（用于 UDP NAT）
6. 路由规则按域名 "example.com" 匹配 → 决定出站
7. 出站连接：
```

**第 7 步是真正 DNS 解析发生的地方，因出站类型而异：**

| 出站类型 | DNS 行为 | 代码路径 |
|---------|---------|---------|
| **proxy**（vless/vmess/trojan/ss/socks5/http） | 域名原样发送给远程代理服务器。**不做本地 DNS 解析。** | protocol/socks/outbound.go: `h.client.DialContext()` — 目标是 FQDN |
| **direct** | 必须本地解析。优先级：1) outbound 的 `domain_resolver`，2) `route.default_domain_resolver`（回退），3) 默认 DNS transport（最后手段） | common/dialer/dialer.go:57-126 → 创建 ResolveDialer → 调用 router.Lookup() |
| **socks4**（旧协议） | 必须本地解析（协议不支持 FQDN） | protocol/socks/outbound.go:86 — `h.resolve` 特殊处理 |

**关键含义：**
- `dns.final`（如 google-dns）在 fakeip 场景下极少使用 — 仅处理非 A/AAAA 查询（MX、TXT、SRV）
- direct outbound 的真实 DNS 服务器由 `route.default_domain_resolver` 控制，**不是** `dns.final`
- proxy outbound 完全不做本地 DNS 解析 — 由代理服务器解析
- `experimental.cache_file` 是 fakeip 跨重启持久化的必要条件（否则报 "missing fakeip record" 错误）

## 路由决策规则

从路由语义出发，不要从 DNS 语义出发。

1. 用户说"这个域名必须走代理"→ 在 CN/直连兜底规则之前添加 `route.rules` 条目，`outbound: "proxy"`。默认不添加 DNS 覆盖。
2. 用户说"这个域名必须直连"→ 同时添加 DNS 规则和路由规则，放在 CN/fakeip 兜底之前，让域名绕过 fakeip 使用真实直连 DNS。
3. 仅在以下情况为代理域名添加 DNS 规则：
   - 更早的 DNS 规则集会将该域名强制发往特定解析器（如 `alidns`）
   - 用户明确要求 `fakeip` 或特定解析器
   - 需要让 DNS 行为与路由路径对齐以便调试或防泄漏
4. 将 `fakeip-dns` 视为显式覆盖，而非对每个自定义代理域名的自动选择。
5. 当用户需要确定性行为时，优先使用显式路由规则而非依赖 `final`。GUI 选择器状态会在运行时改变有效出站。
6. 不要根据站点语言、受众、品牌或 TLD 推断 `geosite-cn` 成员关系。应验证官方规则集源，或明确声明这是假设。

## 平台说明

### macOS (SFM) / Android (SFA) / iOS (SFI)
- 通过 Network Extension / VPN API 实现 VPN，无需 root（Apple 开发者 entitlement `packet-tunnel-provider`，系统内核创建 TUN 设备；命令行 `sing-box run` 则需要 sudo 直接创建 utun）
- **仅 TUN 即可** — VPN 模式捕获所有流量，包括浏览器 HTTP/HTTPS
- SFM 仅在配置包含 `platform.http_proxy.enabled: true` 且 SFM 偏好设置 `systemProxyEnabled` 为 true（默认 true）时设置系统代理
- `auto_detect_interface: true` 防止路由循环
- `stack: "mixed"` 兼容性最佳
- 同一配置可跨所有平台使用

### GUI 选择器状态

- 将 GUI / Clash API 中的当前选择视为 selector outbound（如 `proxy`、`final`、`google`、`apple`）的权威值。
- 不要假设 JSON 中的 `"default"` 值就是当前运行时的值。
- 如果某个域名必须始终走代理/直连（不受 GUI 状态影响），添加显式 `route.rules` 匹配而非依赖 `final`。

### 两种代理模式

sing-box 有两种根本不同的流量捕获方式：

| | TUN 模式 | 系统代理模式 |
|---|---|---|
| 层级 | 网络层（L3），捕获所有 IP 流量 | 应用层（L7），仅捕获遵循系统代理设置的应用 |
| 核心组件 | TUN inbound | mixed/http inbound（代理服务器） |
| 流量范围 | 所有应用，包括不支持代理的 | 浏览器、curl 等支持代理的应用 |
| DNS 控制 | 完整（hijack-dns + fakeip） | 无（应用自行 DNS 解析） |
| macOS 命令行 | 需要 sudo（创建 utun 设备） | 不需要 sudo |
| SFM/SFA/SFI | 默认且唯一模式 | 不支持（App Extension 必须以 VPN 运行） |

### 系统代理的两种配置方式

系统代理模式需要两件事：① 一个 mixed inbound 作为代理服务器监听端口，② 告诉操作系统使用该代理。第②步有两种实现：

| | `set_system_proxy` | `platform.http_proxy` |
|---|---|---|
| 配置位置 | mixed/http inbound 字段 | TUN inbound 的 `platform` 块 |
| 实现 | 调用系统命令（macOS: `networksetup`; Linux: `gsettings`/KDE; Windows: WinINet） | 通过 VPN API（Apple: `NEProxySettings`） |
| 适用场景 | 命令行 `sing-box run` | SFM/SFA/SFI 图形客户端 |
| 依赖 TUN | 不依赖 | 必须有 TUN inbound |
| 命令行可用 | **可用** | **被忽略**（`platformInterface == nil` → `platform` 块不传给 TUN） |
| SFM 可用 | **不推荐**（文档：Apple 无特权环境用 `platform.http_proxy` 替代） | **可用** |

**关键理解：** `platform.http_proxy` 不是代理服务器 — 它只告诉系统"代理在 `server:server_port`"。实际代理服务器由 mixed inbound 提供。使用 `platform.http_proxy` 时必须同时配一个 mixed inbound 监听对应端口。

**使用场景选择：**
- **SFM/SFA/SFI**：只需 TUN inbound（默认）。如需附加 HTTP 代理功能，添加 `platform.http_proxy` + mixed inbound
- **命令行全局代理**：TUN inbound（macOS 需 sudo）
- **命令行轻量代理**：mixed inbound + `set_system_proxy: true`（无需 sudo）
- **手动代理**：mixed inbound，手动在浏览器/应用中配置代理地址

### 可选：platform.http_proxy + mixed inbound

默认不需要。TUN (VPN) 已捕获所有流量。仅在以下场景添加：
- 特定应用只认系统 HTTP 代理，不走 TUN 路由（极少见）
- 需要 `bypass_domain` / `match_domain` 做应用层域名过滤（`match_domain` 仅 Apple 图形客户端支持）

```json
// 添加到 TUN inbound：
"platform": {
  "http_proxy": {
    "enabled": true,
    "server": "127.0.0.1",
    "server_port": 2080,
    "bypass_domain": ["example.com"],
    "match_domain": ["specific-app.com"]
  }
}
// 添加为第二个 inbound：
{ "type": "mixed", "tag": "mixed-in", "listen": "127.0.0.1", "listen_port": 2080 }
```

### 命令行 system proxy 模式配置

不使用 TUN，仅通过 mixed inbound + `set_system_proxy` 实现系统代理。适用于：
- Linux 服务器（无 GUI，不需要/不能用 TUN）
- macOS 命令行 `sing-box run`
- 不想使用 VPN 模式的场景

**限制：** 系统代理仅捕获遵循系统代理设置的应用（浏览器、curl 等）。不走系统代理的应用（如某些游戏、底层网络工具）的流量不会进入 sing-box。这是与 TUN 模式的根本区别。

**各平台 `set_system_proxy` 行为：**
- **macOS**: 调用 `networksetup` 设置代理，普通用户即可（MDM 管控设备可能需要授权）。自动监听网络接口变化并更新。
- **Linux**: 支持 GNOME（`gsettings`）和 KDE（`kwriteconfig5/6`）桌面环境。无桌面环境的服务器上会报错 `unsupported desktop environment`，此时需手动设置 `http_proxy`/`https_proxy` 环境变量。
- **Windows**: 通过 WinINet API 设置系统代理。
- **Android**: 需要 root 或 adb 权限（`settings put global http_proxy`）。

```json
{
  "log": { "level": "info", "timestamp": true },
  "experimental": {
    "cache_file": { "enabled": true },
    "clash_api": {
      "external_controller": "127.0.0.1:9091",
      "secret": "",
      "default_mode": "rule"
    }
  },
  "dns": {
    "servers": [
      { "type": "udp", "tag": "alidns", "server": "223.5.5.5" }
    ],
    "strategy": "ipv4_only"
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 2080,
      "set_system_proxy": true
    }
  ],
  "outbounds": [
    {
      "type": "selector", "tag": "proxy",
      "outbounds": ["auto", "your-node-tag", "direct"], "default": "auto"
    },
    {
      "type": "urltest", "tag": "auto",
      "outbounds": ["your-node-tag"],
      "url": "https://www.gstatic.com/generate_204", "interval": "5m", "tolerance": 50
    },
    { "type": "direct", "tag": "direct" },
    {
      "type": "vless", "tag": "your-node-tag",
      "server": "your-server.example.com", "server_port": 443,
      "uuid": "your-uuid-here"
    }
  ],
  "route": {
    "rules": [
      { "action": "sniff" },
      { "clash_mode": "Direct", "action": "route", "outbound": "direct" },
      { "clash_mode": "Global", "action": "route", "outbound": "proxy" },
      { "rule_set": ["geosite-cn", "geoip-cn"], "action": "route", "outbound": "direct" }
    ],
    "rule_set": [
      { "type": "remote", "tag": "geosite-cn", "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-cn.srs",
        "download_detour": "direct" },
      { "type": "remote", "tag": "geoip-cn", "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/SagerNet/sing-geoip@rule-set/geoip-cn.srs",
        "download_detour": "direct" }
    ],
    "final": "proxy",
    "auto_detect_interface": true,
    "default_domain_resolver": "alidns"
  }
}
```

与 TUN 模板的关键区别：
- inbound 是 `mixed` 而非 `tun`，无需 `auto_route`/`strict_route`/`stack`
- **无 hijack-dns**：系统代理模式下应用自行 DNS 解析，不经过 sing-box DNS 模块，hijack-dns 无流量可劫持
- **无 fakeip**：同上原因，DNS 规则不被触发，fakeip 无意义
- **DNS 极简**：仅保留 alidns 供 `default_domain_resolver` 使用（direct 出站解析域名）
- 无 hosts fallthrough、无防泄漏规则（这些仅在 TUN 全流量模式下有意义）
- `auto_detect_interface` 仍需开启（防止 outbound 路由环路）

## 源码验证指南

当 cookbook、config-schema、官方文档都无法确定某个行为时，直接读源码。这在以下场景尤其重要：
- 字段的**默认值**文档未明确标注
- 某个功能在**特定平台**的行为（如 `set_system_proxy` 在 macOS 是否需要 root）
- **版本变更**后旧文档描述可能不准确
- 配置字段的**类型**（bool vs object vs string）不确定
- 两个功能是否**互斥**（如 `tls_fragment` 和 `tls_record_fragment`）

### 查找路径

| 要确认的内容 | 首先查看的源码位置 |
|-------------|-------------------|
| 配置字段定义（名称、类型、JSON tag） | `option/` 目录（如 `option/tun.go`, `option/rule_action.go`） |
| 默认值 | `constant/` 目录（如 `constant/timeout.go`） |
| 字段验证逻辑 | `option/` 中的 `Validate()` 或 `UnmarshalJSON()` 方法 |
| TUN 路由行为（auto_route, strict_route） | sing-tun 库：`go/pkg/mod/github.com/sagernet/sing-tun@*/` |
| DNS 处理逻辑 | `dns/client.go`, `dns/router.go` |
| 路由匹配 | `route/router.go`, `route/rule.go` |
| 平台特定行为（系统代理） | `common/settings/proxy_*.go` |
| Apple 客户端行为 | `clients/apple/Library/Network/` |
| libbox（图形客户端接口） | `experimental/libbox/` |

### 版本对齐

源码验证必须匹配用户实际使用的 sing-box 版本，否则可能得出错误结论（字段在新版添加/移除、默认值变更、行为修改）。

1. **确认用户版本**：询问用户 sing-box 版本，或从配置中的功能使用推断（如使用了 `action` 字段 → v1.11+，使用了 `type` DNS 服务器 → v1.12+）
2. **切换到对应版本**：如果本地有仓库，`git checkout v1.12.0`（或对应 tag）后再读代码。tag 列表：`git tag -l 'v1.*'`
3. **外部依赖版本**：`go.mod` 中锁定了依赖版本（如 `sing-tun v0.8.3`），在 `go/pkg/mod/` 缓存中找到对应版本目录

### 验证方法

1. **本地仓库**（推荐）：如果用户的工作目录是 sing-box 仓库或本地有克隆，先确认分支/tag 与用户版本一致，再用 Grep/Read 工具读取
2. **GitHub**：使用 `gh api` 或 WebFetch 获取 `https://github.com/sagernet/sing-box` 上的文件（可指定 tag：`https://github.com/sagernet/sing-box/blob/v1.12.0/option/rule_action.go`）
3. **go.mod 依赖**：外部库（如 sing-tun）在 `go/pkg/mod/` 缓存中，路径从 `go.mod` 获取版本号

### 原则

- **不要猜测** — 如果不确定，读代码再回答
- **引用具体位置** — 回答时标注文件名和行号（如 "verified in `option/rule_action.go:183`"），让用户可以自行确认
- **区分 "文档说" 和 "代码做"** — 如果发现文档与代码不一致，以代码为准，并告知用户

## 转换代理节点

### 通用字段映射（Clash YAML → sing-box JSON）

| Clash | sing-box |
|-------|----------|
| `server` / `port` | `"server"` / `"server_port"` |
| `tls: true` | `"tls": { "enabled": true }` |
| `servername` / `sni` | `"tls.server_name"` |
| `skip-cert-verify: true` | `"tls.insecure": true` |
| `client-fingerprint` | `"tls.utls": { "enabled": true, "fingerprint": "..." }` |
| `reality-opts.public-key` | `"tls.reality": { "enabled": true, "public_key": "..." }` |
| `reality-opts.short-id` | `"tls.reality.short_id"` |
| `network: ws` | `"transport": { "type": "ws", "path": "..." }` |
| `network: grpc` | `"transport": { "type": "grpc", "service_name": "..." }` |
| `network: h2` | `"transport": { "type": "http", "host": [...] }` |
| `ws-opts.path` | `"transport.path"` |
| `ws-opts.headers.Host` | `"transport.headers": { "Host": ["..."] }` |
| `grpc-opts.grpc-service-name` | `"transport.service_name"` |

### 各协议转换示例

**VLESS:**
```json
{ "type": "vless", "server": "...", "server_port": 443, "uuid": "...", "flow": "xtls-rprx-vision",
  "tls": { "enabled": true, "server_name": "...", "utls": { "enabled": true, "fingerprint": "chrome" },
    "reality": { "enabled": true, "public_key": "...", "short_id": "..." } } }
```

**VMess:**
```json
{ "type": "vmess", "server": "...", "server_port": 443, "uuid": "...", "security": "auto",
  "tls": { "enabled": true, "server_name": "..." },
  "transport": { "type": "ws", "path": "/path", "headers": { "Host": ["example.com"] } } }
```
Clash `cipher` → sing-box `security`。`alter_id` 默认 0（AEAD），非 0 是旧版不安全。

**Shadowsocks:**
```json
{ "type": "shadowsocks", "server": "...", "server_port": 8388, "method": "2022-blake3-aes-128-gcm", "password": "***" }
```
Clash `cipher` → sing-box `method`。`plugin: obfs` → `"plugin": "obfs-local"`, `"plugin_opts": "obfs=http;obfs-host=..."`.

**Trojan:**
```json
{ "type": "trojan", "server": "...", "server_port": 443, "password": "***",
  "tls": { "enabled": true, "server_name": "..." } }
```

**Hysteria2:**
```json
{ "type": "hysteria2", "server": "...", "server_port": 443, "password": "***",
  "up_mbps": 100, "down_mbps": 200,
  "obfs": { "type": "salamander", "password": "***" },
  "tls": { "enabled": true, "server_name": "..." } }
```
Clash `auth` → sing-box `password`。`obfs: salamander` → `"obfs": { "type": "salamander", "password": "***" }`。

**TUIC:**
```json
{ "type": "tuic", "server": "...", "server_port": 443, "uuid": "...", "password": "***",
  "congestion_control": "bbr", "udp_relay_mode": "native",
  "tls": { "enabled": true, "server_name": "...", "alpn": ["h3"] } }
```

**ShadowTLS + Shadowsocks（链式）:**
```json
{ "type": "shadowtls", "tag": "st", "server": "...", "server_port": 443, "version": 3, "password": "***",
  "tls": { "enabled": true, "server_name": "www.microsoft.com", "utls": { "enabled": true, "fingerprint": "chrome" } } },
{ "type": "shadowsocks", "tag": "ss-via-st", "method": "2022-blake3-aes-128-gcm", "password": "***",
  "detour": "st", "udp_over_tcp": { "enabled": true } }
```

IP 格式的服务器地址不需要 `domain_resolver`。

## 可用规则集标签

**Geosite**（域名）：
- 国内：`geosite-cn`、`geosite-geolocation-cn`
- 广泛海外：`geosite-geolocation-!cn`
- Google：`geosite-google`、`geosite-google@cn`、`geosite-youtube`、`geosite-google-gemini`
- Microsoft：`geosite-microsoft`、`geosite-microsoft@cn`、`geosite-github`、`geosite-github-copilot`
- Apple：`geosite-apple`、`geosite-apple@cn`、`geosite-apple-intelligence`
- AI：`geosite-openai`、`geosite-anthropic`、`geosite-jetbrains-ai`、`geosite-category-ai-chat-!cn`、`geosite-xai`
- Steam：`geosite-steam`、`geosite-steam@cn`
- 社交：`geosite-telegram`、`geosite-discord`
- 流媒体：`geosite-netflix`、`geosite-spotify`
- 广告：`geosite-category-ads-all`

**Geoip**（IP）：国家代码 — `geoip-cn`、`geoip-us`、`geoip-jp` 等。

## 常见海外站点使用规则集

当用户希望常见海外网站始终走代理（即使在 GUI 中切换了 `final`），优先使用显式的广泛规则集：

```json
{
  "rule_set": "geosite-geolocation-!cn",
  "action": "route",
  "outbound": "proxy"
}
```

添加对应的远程规则集：

```json
{
  "type": "remote",
  "tag": "geosite-geolocation-!cn",
  "format": "binary",
  "url": "https://testingcf.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-geolocation-!cn.srs",
  "download_detour": "direct"
}
```

将路由规则放在 `geosite-cn` / `geoip-cn -> direct` 之前。

## 自定义域名直连

添加两条规则 — 一条 DNS + 一条路由 — 都放在 CN/fakeip 兜底之前：

```json
// DNS：绕过 fakeip，使用真实 DNS
{ "domain_suffix": ["example.com"], "action": "route", "server": "local-dns" }

// 路由：直连
{ "domain_suffix": ["example.com"], "action": "route", "outbound": "direct" }
```

`domain_suffix` 不带前导 `.` 时匹配域名本身及所有子域名。

## 自定义域名走代理

默认：仅添加路由规则，放在 `geosite-cn` / `geoip-cn` 和 `final` 之前：

```json
{ "domain_suffix": ["example.com"], "action": "route", "outbound": "proxy" }
```

仅在有特定理由覆盖默认 DNS 路径时才添加对应的 DNS 规则：

```json
{ "domain_suffix": ["example.com"], "action": "route", "server": "fakeip-dns" }
```

或

```json
{ "domain_suffix": ["example.com"], "action": "route", "server": "google-dns" }
```

仅当更早的 DNS 规则会将域名发往错误的解析器时，或用户明确要求 `fakeip` / 非 `fakeip` 行为时，才使用 DNS 覆盖。

## 调试

| 症状 | 原因 | 修复 |
|------|------|------|
| 所有 DNS 失败，无网络 | hijack-dns 仅使用 `protocol: dns` | 使用 `port: 53` 或逻辑 OR 并在前面加 `action: sniff` |
| DNS 解析的域名出现 IPv6 `no route to host` | 网络缺乏 IPv6 | `dns.strategy: "ipv4_only"` |
| 微信等使用 HTTPDNS 的应用出现 IPv6 `no route to host` | TUN IPv6 地址欺骗应用认为 IPv6 可用；HTTPDNS 绕过 sing-box DNS | 从 TUN `address` 中移除 IPv6（见关键规则 #4） |
| 规则集无法下载 | GitHub 在国内被墙 | 切换到 `testingcf.jsdelivr.net` CDN |
| 浏览器 `ERR_PROXY_CONNECTION_FAILED` | 系统/浏览器有残留代理配置 | 检查 Chrome 扩展（SwitchyOmega），或添加 `platform.http_proxy` + mixed inbound |
| 添加直连规则后域名仍获得 fakeip | 缓存的 fakeip 映射 | 清除 SFM 缓存，重启 VPN |
| GUI 切换后站点意外走直连/代理 | GUI 选择器状态与 JSON `"default"` 不同 | 检查 GUI / Clash API 中的当前选择；如需固定行为添加显式路由规则 |
| 启动崩溃："dns outbound deprecated" | v1.13 移除了 dns outbound | 删除它，使用 `hijack-dns` action |
| 启动崩溃："block outbound deprecated" | v1.13 移除了 block outbound | 删除它，使用 `"action": "reject"` |
| multiplex 连接失败 | 服务端未开启 multiplex | 确认服务端也启用了 multiplex 并匹配 protocol |
| ShadowTLS 连接超时 | version 不匹配或 password 错误 | 确认客户端/服务端 version 和 password 一致 |
| hysteria2 连接被重置 | TLS server_name 不匹配或 obfs 配置不一致 | 检查 TLS 和 obfs 设置与服务端匹配 |
| WireGuard "no route" | endpoint 放在了 outbounds 而非 endpoints | WireGuard 应放在顶层 `"endpoints": [...]` |
| 特定 App 不走代理 (Android) | 未包含在 include_package 中 | 使用 `exclude_package`（默认全部代理）代替 `include_package` |
| WiFi 切蜂窝后断连 | 未配置 network_strategy | 设置 `"default_network_strategy": "hybrid"` 或 `"fallback"` |