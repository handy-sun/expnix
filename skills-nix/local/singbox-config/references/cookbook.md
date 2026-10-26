# sing-box Cookbook — 工作原理与配置模式

> 本文解释 sing-box 各组件的**执行流程和交互关系**，不是字段列表（字段列表见 config-schema.md）。

## 1. 连接生命周期：从 TUN 到目标

```
App 发起连接 (e.g. curl google.com)
  │
  ▼
① TUN 捕获 IP 包 → 创建 InboundContext (源IP/端口, 目标IP/端口)
  │
  ▼
② matchRule() — 主路由引擎，按顺序遍历 route.rules
  │
  ├─ 查找进程信息 (process_name/path)
  ├─ FakeIP 反查：目标 IP 在 fakeip store 中？
  │    是 → metadata.Destination 从 IP 还原为域名，标记 FakeIP=true
  │
  ├─ 遍历规则 (first-final-action-wins):
  │    Rule 0: action=sniff → 偷看数据，识别协议/域名，【不中断，继续下一条】
  │    Rule 1: action=hijack-dns → 匹配成功？→ 转 DNS 处理 【中断】
  │    Rule 2: action=route → 匹配成功？→ 选定 outbound 【中断】
  │    Rule N: ...
  │
  ▼
③ 执行 final action:
   hijack-dns → 进入 DNS 路由（见第2节）
   route      → 连接发送到选定 outbound
   reject     → 返回 RST/ICMP unreachable 或静默丢弃
```

### 关键理解

**非终结动作 (sniff/resolve/route-options) 不中断规则遍历。** 它们修改 metadata 后继续匹配下一条规则。这意味着：

```
Rule 0: { "action": "sniff" }              ← 识别出域名 google.com
Rule 1: { "domain": "google.com", ... }    ← 现在可以匹配域名了
```

如果 sniff 放在 domain 匹配之后，域名还没识别出来，匹配会失败。**顺序决定一切。**

**终结动作 (route/reject/hijack-dns) 立即中断。** 第一个匹配的终结动作决定这条连接的命运，后续规则不再评估。

### FakeIP 反查时机

FakeIP 反查发生在规则遍历**之前**（matchRule 的第一步）。这意味着：
- App 连接 198.18.0.32:443
- matchRule 先查 fakeip store → 发现 198.18.0.32 = google.com
- metadata.Destination 变为 google.com
- 后续规则基于域名 google.com 匹配，而非 IP

## 2. DNS 查询流程

DNS 查询有两个入口：

```
入口 A: hijack-dns（路由规则劫持）
  App 的 DNS 查询（UDP/TCP port 53）→ 路由规则匹配 → hijack-dns → DNS 路由

入口 B: domain_resolver（出站域名解析）
  Outbound 需要解析域名 → 直接调用指定 DNS 服务器，【绕过 dns.rules】
```

### DNS 规则匹配

```
DNS 查询到达
  │
  ▼
遍历 dns.rules（顺序匹配，第一个终结动作生效）:
  │
  ├─ 匹配条件: 同类字段 OR，不同类字段 AND
  │   例: domain_suffix=["cn","com.cn"] AND query_type=["A"]
  │   含义: (后缀是 cn 或 com.cn) 且 (查询类型是 A)
  │
  ├─ 动作:
  │   route  → 发送到指定 DNS 服务器
  │   reject → 返回 NXDOMAIN
  │
  ├─ 响应过滤 (仅 A/AAAA/HTTPS):
  │   ip_accept_any: 响应包含任意 IP 就接受
  │   ip_cidr: 响应 IP 在指定 CIDR 范围内才接受
  │   ip_is_private: 响应 IP 是私有地址才接受
  │
  │   ↳ 如果响应不满足过滤条件 → 跳过此规则，继续匹配下一条
  │
  ▼
无规则匹配 → 使用 dns.final 指定的服务器
```

### ip_accept_any 的真正含义

**它是响应过滤器，不是查询过滤器。** 执行顺序：

1. 查询发送到 hosts 服务器
2. hosts 返回响应（可能有 IP，可能为空）
3. `ip_accept_any` 检查：响应中有任何 IP 吗？
   - 有 → 接受此响应，规则匹配成功
   - 没有 → 规则匹配失败，**继续下一条规则**

这实现了 "先查 hosts，查不到就 fallthrough" 的模式：
```json
{ "ip_accept_any": true, "action": "route", "server": "hosts" }
```

### RDRC（拒绝 DNS 响应缓存）

RDRC 缓存 DNS 响应过滤器（`ip_cidr`、`ip_is_private`、`ip_accept_any`）的拒绝结果。

工作流程：
1. DNS 查询 `google.com` 匹配到 `alidns`（国内 DNS）规则
2. alidns 返回被污染的 IP（如 `203.0.113.1`）
3. 规则的响应过滤（如 `ip_cidr` 不匹配或 `ip_accept_any` 为空）拒绝此响应
4. RDRC 缓存：`alidns + google.com + A → rejected`
5. 下次 `google.com` 查询到达时，直接跳过 alidns 规则，不发送实际 DNS 请求
6. 继续匹配下一条规则（如 fakeip 或 google-dns）

**为什么重要：** 在 hosts fallthrough 模式（`ip_accept_any`）中，hosts 对大多数域名返回空结果 → 每次查询都要先问 hosts 再 fallthrough。RDRC 缓存空结果后，后续查询直接跳过 hosts 规则。

`store_rdrc: true` 将 RDRC 持久化到 cache.db，重启后不丢失。`rdrc_timeout` 默认 7 天。

### independent_cache 的作用

- `false`（默认）：全局缓存，相同域名不同 DNS 服务器共享缓存
- `true`：每个 DNS 服务器独立缓存

为什么分流场景必须 `true`：如果 google.com 先被 alidns 解析（返回污染 IP），缓存后 google-dns 也会命中这个污染结果。独立缓存避免交叉污染。

## 3. DNS 策略 (strategy) 工作方式

strategy 同时在**查询和响应两个阶段**过滤：

| 策略 | 查询阶段 | 响应阶段 |
|------|---------|---------|
| `ipv4_only` | 收到 AAAA 查询 → 直接返回空成功 | 只返回 A 记录 |
| `ipv6_only` | 收到 A 查询 → 直接返回空成功 | 只返回 AAAA 记录 |
| `prefer_ipv4` | 两种都查 | A 记录排前面 |
| `prefer_ipv6` | 两种都查 | AAAA 记录排前面 |

`ipv4_only` 不是"丢弃 AAAA 响应"，而是根本不发 AAAA 查询，所以完全不会产生 IPv6 地址。

## 4. FakeIP 完整生命周期

```
① DNS 查询: google.com A?
   │
   ▼
② dns.rules 匹配到 fakeip 服务器
   │
   ▼
③ FakeIP 生成:
   - 从 inet4_range (198.18.0.0/15) 中顺序分配 IP
   - 存储双向映射: 198.18.0.32 ↔ google.com
   - store_fakeip=true 时持久化到 cache.db
   │
   ▼
④ 返回 198.18.0.32 给 App
   │
   ▼
⑤ App 连接 198.18.0.32:443
   │
   ▼
⑥ TUN 捕获 → matchRule():
   - 查 fakeip store: 198.18.0.32 → google.com
   - metadata.Destination = google.com (不再是 IP)
   - metadata.FakeIP = true
   │
   ▼
⑦ 路由规则基于域名 google.com 匹配
   │
   ▼
⑧ Outbound 使用域名 google.com 建立连接
   (代理协议发送域名，远端服务器解析真实 IP)
```

### FakeIP 第 7 步：出站类型决定 DNS 解析方式（源码验证）

FakeIP 反查还原域名后，路由规则选定了出站，此时真正的 DNS 解析行为因出站类型而异：

| 出站类型 | DNS 行为 |
|---------|---------|
| **proxy**（vless/vmess/trojan/ss/socks5/http） | 域名原样发送给远程代理服务器。**不做本地 DNS 解析。** |
| **direct** | 必须本地解析。优先级：1) outbound 的 `domain_resolver`，2) `route.default_domain_resolver`（回退），3) 默认 DNS transport |

**关键含义：**
- `dns.final`（如 google-dns）在 fakeip 场景下极少使用 — 仅处理非 A/AAAA 查询（MX、TXT、SRV）
- direct outbound 的真实 DNS 由 `route.default_domain_resolver` 控制，**不是** `dns.final`
- proxy outbound 完全不做本地 DNS — 代理服务器负责解析

### FakeIP 缓存陷阱

`store_fakeip: true` 将映射持久化。如果你**修改了 DNS 规则让某域名绕过 fakeip**，旧的 fakeip 映射仍然存在：
- 查询到达 → dns.rules 匹配到新规则 → 用 alidns 解析 → 返回真实 IP ✓
- 但如果 App 缓存了旧的 fakeip 地址直接连接 → TUN 查 fakeip store 仍能找到映射 → 还是走 fakeip 路径

**解决方案：** 修改 fakeip 相关规则后，必须清除 SFM 缓存并重启 VPN。

## 5. 路由规则匹配逻辑

### 条件组合规则

单条规则内：**不同类型字段 AND，同类型字段 OR**

```json
{
  "domain_suffix": [".google.com", ".youtube.com"],  ← OR: 匹配任一后缀
  "port": [80, 443],                                  ← OR: 匹配任一端口
  "network": "tcp",                                    ← AND: 必须是 TCP
  "action": "route", "outbound": "proxy"
}
```
含义：`(google.com 或 youtube.com) 且 (80 或 443 端口) 且 (TCP)` → proxy

### logical 规则

用 `"type": "logical"` 实现更复杂的组合：

```json
{
  "type": "logical",
  "mode": "or",      // 子规则之间 OR（也可以 "and"）
  "rules": [
    { "protocol": "dns" },
    { "port": 53 }
  ],
  "action": "hijack-dns"
}
```

### 规则顺序的陷阱

路由规则是**顺序短路**的。常见错误：

```
❌ 错误顺序:
  Rule: ip_is_private → direct     ← 172.19.0.2 (TUN 网关) 匹配！
  Rule: port 53 → hijack-dns      ← 永远到不了

✅ 正确顺序:
  Rule: action=sniff               ← 先嗅探协议
  Rule: port 53 OR protocol dns → hijack-dns  ← DNS 先处理
  Rule: ip_is_private → direct     ← 其他私有 IP 才走直连
```

另一个例子（anti-leak 拦截国内应用）：
```
❌ 错误:
  Rule: reject UDP 443             ← 微信 QUIC 在这里被杀
  Rule: geosite-cn → direct        ← 微信到不了这里

✅ 正确: 不要全局拒绝 UDP 443，或把 CN 规则提前
```

## 6. auto_route / strict_route / auto_detect_interface

### auto_route 的实际行为

`auto_route` 将系统默认路由指向 TUN 接口，使所有流量进入 TUN：

- **Linux**: 创建 iproute2 policy routing 规则（默认表 2022，规则优先级从 9000 开始），将匹配的流量导向 TUN 路由表
- **macOS (命令行)**: 通过系统路由表添加路由（使用子网拆分避免覆盖默认路由）
- **macOS/iOS/Android (图形客户端)**: 通过 Network Extension / VpnService API 设置，由系统管理路由

`auto_route` 只做路由，**不做防环**。必须配合 `route.auto_detect_interface` 或 `route.default_interface` 使用。

### strict_route 的含义

`strict_route` 因平台而异：

**Linux:**
- 对 TUN **未配置**的地址族（如没配 IPv6 地址），添加 `UNREACHABLE` 规则 → 该协议族流量直接报错而非泄漏到真实接口
- 不开 `strict_route` 且不开 `auto_redirect` 时，所有 ICMP 流量不走 TUN
- 开了 `auto_redirect` 后，`strict_route` 还控制 `SO_BINDTODEVICE` 流量（如 Docker）是否被重定向进 sing-box

**Windows:**
- 防止 Windows 多宿主 DNS 解析行为导致的 DNS 泄漏（Windows 默认会同时查询所有网络接口的 DNS）

**macOS/移动端:**
- 无特殊作用（VPN 模式本身已完整捕获流量）

### auto_detect_interface 防环机制

`auto_detect_interface` 本身**不防止环路**。它做的是：

1. 监听系统默认网络接口变化
2. 当 outbound 没有显式绑定接口时，自动绑定到检测到的默认接口

**防环的真正原理：**
- TUN 接口接收流量（通过路由表）
- Outbound 发出流量时绑定到**物理接口**（如 en0），绕过 TUN
- 物理接口的流量不会再被路由回 TUN

如果 `auto_detect_interface: false`，outbound 不绑定接口，发出的流量可能被路由表送回 TUN → 死循环。

### auto_redirect (Linux 推荐)

`auto_redirect` 在 `auto_route` 基础上，使用 nftables 实现更高效的流量重定向：
- 性能优于 tproxy
- 避免 TUN 与 Docker 网桥冲突
- 支持 OpenWrt fw4 自动兼容
- 推荐在 Linux 上始终启用

## 7. domain_resolver vs dns.rules

这是两个完全独立的 DNS 解析路径：

| | dns.rules | domain_resolver |
|---|---|---|
| 触发 | hijack-dns 劫持的 DNS 查询 | outbound 解析服务器域名 |
| 规则 | 走 dns.rules 完整匹配 | 直接使用指定 DNS 服务器，**不走 dns.rules** |
| 场景 | App 的 DNS 查询 | 代理节点地址解析、rule-set URL 解析 |
| 配置 | `dns.rules` | outbound 上的 `domain_resolver` 或 route 上的 `default_domain_resolver` |

这意味着：即使 dns.rules 里有复杂的分流逻辑，`default_domain_resolver: "alidns"` 解析代理节点域名时完全不受 dns.rules 影响。

## 8. TUN 栈选择

| 栈 | TCP | UDP | 兼容性 | 性能 |
|---|---|---|---|---|
| `system` | 系统 TCP 栈 | 不支持 | 最好的 TCP 兼容 | 高 |
| `gvisor` | 用户态 TCP | 用户态 UDP | 完整但可能有边缘问题 | 中 |
| `mixed` | 系统 TCP | gvisor UDP | **推荐** | 高 |

`mixed` 结合两者优势：TCP 用系统栈保证兼容性，UDP 用 gvisor 保证支持。

## 9. 常见配置模式

### 模式 A: "先查后匹配" (hosts fallthrough)
```json
{ "ip_accept_any": true, "server": "hosts" }  // 有结果就用，没结果继续
```

### 模式 B: "国内外 DNS 分流"
```json
{ "rule_set": "geosite-cn", "server": "alidns" },     // 国内域名 → 国内 DNS
{ "query_type": ["A","AAAA"], "server": "fakeip-dns" } // 其他 → FakeIP
```
顺序重要：geosite-cn 必须在 fakeip 之前，否则国内域名也会被 fakeip 劫持。

### 模式 C: "域名直连绕过 FakeIP"
需要 DNS + 路由双规则，且都在 fakeip/CN 规则之前：
```json
// dns.rules: 真实解析
{ "domain_suffix": ["example.com"], "server": "local-dns" }
// route.rules: 直连
{ "domain_suffix": ["example.com"], "outbound": "direct" }
```

### 模式 D: "按服务分流"
```json
// outbounds: 每个服务一个 selector
{ "type": "selector", "tag": "google", "outbounds": ["proxy","direct"] }
// route.rules: 服务 → 对应 selector
{ "rule_set": "geosite-google", "outbound": "google" }
```
用户可通过 Clash API 面板为每个服务单独切换代理/直连。

## 10. HTTPDNS 与 TUN IPv6 陷阱

### 问题

微信等应用使用 HTTPDNS（通过 HTTP 请求获取 IP 地址）而非标准 DNS。HTTPDNS 的响应在 HTTP 载荷内部，sing-box 的 DNS 模块完全看不到。因此 `dns.strategy: "ipv4_only"` 无法阻止这些应用获取 IPv6 地址。

### TUN IPv6 地址的致命影响

当 TUN 配置了 IPv6 地址时，系统创建 IPv6 路由，应用认为 IPv6 可用：
- 微信通过 HTTPDNS 获取 `wx.qlogo.cn` 的 IPv6 地址
- 应用连接 IPv6 → 进入 TUN → direct outbound → 真实网卡无 IPv6 → 失败
- 应用看到有效的 IPv6 路由（指向 TUN），持续重试而不回退 IPv4（Happy Eyeballs 失效）

**无 TUN 时微信正常**是因为：系统无 IPv6 路由 → 内核立即返回 `ENETUNREACH` → 应用通过 Happy Eyeballs 瞬间回退 IPv4。

### 修复

移除 TUN 的 IPv6 地址，仅保留 IPv4：
```json
"address": "172.19.0.1/30"
```

`dns.strategy: "ipv4_only"` 仍需保留（对标准 DNS 有效），但它不解决 HTTPDNS 的问题。

## 11. 代理链（Chained Outbounds / Detour）

使用 `detour` 字段将多个 outbound 串联。内层 outbound 通过外层 outbound 的隧道发送流量。

```
App → sing-box → ShadowTLS (外层) → Shadowsocks (内层) → 目标
```

```json
// 外层：ShadowTLS 伪装
{
  "type": "shadowtls", "tag": "st-out",
  "server": "example.com", "server_port": 443,
  "version": 3, "password": "st-password",
  "tls": { "enabled": true, "server_name": "www.microsoft.com", "utls": { "enabled": true, "fingerprint": "chrome" } }
}
// 内层：Shadowsocks 经 ShadowTLS 隧道
{
  "type": "shadowsocks", "tag": "ss-out",
  "server": "127.0.0.1", "server_port": 0,
  "method": "2022-blake3-aes-128-gcm", "password": "ss-password",
  "detour": "st-out",
  "udp_over_tcp": { "enabled": true }
}
```

`server`/`server_port` 在有 `detour` 时被忽略，流量直接进入 detour 指定的 outbound。但字段仍需存在（可设为任意值）。

## 12. 多路复用（Multiplex / Mux）

将多条连接合并到单个底层 TCP 连接中，减少握手开销，可选流量填充。

```json
{
  "type": "vless",
  "multiplex": {
    "enabled": true,
    "protocol": "h2mux",
    "max_connections": 4,
    "min_streams": 4,
    "padding": true,
    "brutal": { "enabled": true, "up_mbps": 50, "down_mbps": 100 }
  }
}
```

- `h2mux` 推荐（HTTP/2 多路复用），`smux` 兼容性更好但效率低
- `brutal` 开启 TCP Brutal 拥塞控制（需服务器同时支持并启用 brutal）
- `padding: true` 填充随机字节，抵抗流量分析
- **注意：** 服务器端也必须开启 multiplex，否则连接失败

## 13. TLS 分片（Anti-DPI）

将 TLS ClientHello 拆分为小片段，绕过 DPI 深度包检测。

### 方式 A：全局 TLS 选项
```json
{
  "tls": {
    "enabled": true,
    "fragment": true,
    "fragment_fallback_delay": "500ms",
    "record_fragment": true
  }
}
```

### 方式 B：按路由规则（route-options）
```json
{
  "rule_set": "geosite-geolocation-!cn",
  "action": "route-options",
  "tls_fragment": { "enabled": true, "size": "1:5", "delay": "0:5" }
}
```

`size` 和 `delay` 使用 `"min:max"` 格式（字节/毫秒），每次随机取值。

## 14. Android 分应用代理

使用 `include_package` / `exclude_package` 控制哪些 App 走 TUN：

```json
{
  "type": "tun",
  "include_package": [
    "com.google.android.youtube",
    "org.telegram.messenger"
  ]
}
```

或排除模式（代理所有 App 除了指定的）：
```json
{
  "type": "tun",
  "exclude_package": [
    "com.tencent.mm",
    "com.tencent.mobileqq"
  ]
}
```

**不要同时使用 include 和 exclude。** 通常 `exclude_package` 更实用 — 默认全部代理，排除不需要的。

## 15. 网络策略（移动设备 WiFi/蜂窝切换）

`network_strategy` 控制 outbound 在多网络环境下的行为（如手机 WiFi + 蜂窝）：

```json
{
  "route": {
    "default_network_strategy": "hybrid",
    "default_network_type": ["wifi"],
    "default_fallback_network_type": ["cellular"],
    "default_fallback_delay": "100ms"
  }
}
```

| 策略 | 行为 |
|------|------|
| `default` | 仅使用默认网络接口 |
| `hybrid` | 同时尝试所有可用网络，使用最快的 |
| `fallback` | 先尝试首选网络，超时后回退到备选 |

也可在单个 outbound 的 dial fields 中设置 `network_strategy`、`network_type`、`fallback_network_type`。

## 16. WiFi SSID 条件路由

根据当前连接的 WiFi 网络名称切换行为：

```json
{
  "wifi_ssid": ["HomeWiFi", "OfficeWiFi"],
  "action": "route",
  "outbound": "direct"
}
```

适用场景：在公司/家庭 WiFi 直连，在外部 WiFi 走代理。可结合 DNS 规则使用。

## 17. ECH（加密客户端 Hello）

ECH 加密 TLS 握手中的 SNI，防止中间设备检测目标域名。

```json
{
  "tls": {
    "enabled": true,
    "server_name": "example.com",
    "ech": {
      "enabled": true
    }
  }
}
```

三种配置模式：
1. **自动 DNS 查询**（推荐）：只设 `"enabled": true`，sing-box 自动查询 DNS HTTPS 记录获取 ECH 配置
2. **手动配置**：`"config": ["base64-encoded-ECHConfigList"]`
3. **文件路径**：`"config_path": "path/to/ech.pem"`

**注意：** ECH 需要服务端支持。CloudFlare 等 CDN 通常支持。
