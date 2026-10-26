# sing-box Configuration Schema Reference (v1.12+)

> Authoritative docs: https://sing-box.sagernet.org/configuration/
> When in doubt about a field, fetch the latest docs with WebFetch.

## DNS Servers

Each server has `type`, `tag`, and type-specific fields. All remote servers support **Dial Fields**.

| Type | Default Port | Key Fields |
|------|-------------|------------|
| `udp` | 53 | `server`, `server_port` |
| `tcp` | 53 | `server`, `server_port` |
| `tls` | 853 | `server`, `server_port`, `tls` |
| `https` | 443 | `server`, `server_port`, `path` (/dns-query), `headers`, `tls` |
| `h3` | 443 | `server`, `server_port`, `path`, `headers`, `tls` |
| `quic` | 853 | `server`, `server_port`, `tls` |
| `local` | - | `prefer_go` (1.13.0+) — uses system resolver |
| `fakeip` | - | `inet4_range` (198.18.0.0/15), `inet6_range` (fc00::/18) |
| `dhcp` | - | `interface` |
| `hosts` | - | `path` (default /etc/hosts), `predefined` (domain→IP map) |
| `tailscale` | - | `service` (tag of tailscale endpoint) |
| `resolved` | - | `service` (tag of resolved service) |

## DNS Rules

Match conditions combined with AND. Use `"type": "logical"` with `"mode": "and"|"or"` for complex logic.

### Query Match Fields
`inbound`, `ip_version`, `query_type` (A/AAAA/HTTPS/etc), `network`, `protocol`, `domain`, `domain_suffix`, `domain_keyword`, `domain_regex`, `source_ip_cidr`, `source_ip_is_private`, `port`, `port_range`, `process_name`, `process_path`, `clash_mode`, `network_type`, `wifi_ssid`, `rule_set`, `invert`

### Response Filter Fields (A/AAAA/HTTPS only)
`ip_cidr`, `ip_is_private`, `ip_accept_any`

### DNS Rule Actions
- `"action": "route"` — route to server: `server` (required), `strategy`, `disable_cache`, `rewrite_ttl`, `client_subnet`
- `"action": "route-options"` — set options without routing: `disable_cache`, `rewrite_ttl`, `client_subnet`（非终结动作）
- `"action": "reject"` — 默认返回 REFUSED (`method: "default"`)，或 `"drop"` 丢弃请求。`no_drop`: 30 秒内触发 50 次后自动临时切换为 drop
- `"action": "predefined"` — 返回预定义响应：`rcode`（NOERROR/NXDOMAIN/SERVFAIL/REFUSED）、`answer`/`ns`/`extra`（DNS 记录文本）

## Route Rules

### Match Fields
`inbound`, `ip_version`, `network` (tcp/udp/icmp), `protocol`, `client`, `domain`, `domain_suffix`, `domain_keyword`, `domain_regex`, `source_ip_cidr`, `source_ip_is_private`, `ip_cidr`, `ip_is_private`, `source_port`, `port`, `port_range`, `process_name`, `process_path`, `process_path_regex`, `package_name`, `user`, `user_id`, `clash_mode`, `network_type`, `network_is_expensive`, `wifi_ssid`, `wifi_bssid`, `rule_set`, `rule_set_ip_cidr_match_source`, `preferred_by`, `invert`

### Final Actions
- `"action": "route"` — `outbound` (required) + route-options fields
- `"action": "reject"` — `method`: `default` (RST/ICMP) or `drop`
- `"action": "hijack-dns"` — redirect DNS to sing-box DNS module (no fields)
- `"action": "bypass"` — kernel-level bypass (1.13.0+, Linux auto_redirect only)

### Non-Final Actions (processing continues to next rule)
- `"action": "sniff"` — protocol detection. `sniffer` (list), `timeout` (300ms)
- `"action": "resolve"` — DNS resolve. `server`, `strategy`, `disable_cache`
- `"action": "route-options"` — set options: `override_address`, `override_port`, `udp_connect`, `udp_timeout`, `tls_fragment`, `tls_record_fragment`

## TUN Inbound

```json
{
  "type": "tun",
  "tag": "tun-in",
  "address": ["172.19.0.1/30", "fdfe:dcba:9876::1/126"],
  "mtu": 9000,
  "auto_route": true,
  "strict_route": true,
  "stack": "mixed",
  "platform": {
    "http_proxy": {
      "enabled": true,
      "server": "127.0.0.1",
      "server_port": 2080,
      "bypass_domain": [],
      "match_domain": []
    }
  }
}
```

Key fields:
- `address`: TUN interface addresses (IPv4/IPv6 prefixes)
- `auto_route`: 将系统默认路由指向 TUN 接口，使所有流量进入 TUN。Linux 通过 iproute2 policy routing（表 2022）实现，macOS 通过系统路由表实现。**必须同时配置 `route.auto_detect_interface` 或 `route.default_interface` 防止路由环路。**
- `strict_route`: 含义因平台不同：
  - **Linux**: 对 TUN 未配置的地址族添加 UNREACHABLE 规则（如没配 IPv6 地址 → IPv6 流量直接报错而非泄漏到真实接口）。不开 strict_route 且不开 auto_redirect 时，ICMP 不走 TUN。开了 auto_redirect 后还控制 `SO_BINDTODEVICE` 流量是否重定向。
  - **Windows**: 防止 Windows 多宿主 DNS 解析行为导致的 DNS 泄漏。
  - **macOS/移动端**: 无特殊作用（VPN 模式本身已完整捕获流量）。
- `stack`: `system` (TCP only), `gvisor` (full userspace), `mixed` (system TCP + gvisor UDP, best compatibility)
- `platform.http_proxy`: 在 TUN (VPN) 内部设置系统 HTTP 代理。通过 Network Extension API 实现（SFM/SFA/SFI），不需要额外权限。详见下方 "TUN Platform Options"。
- `auto_redirect`: nftables redirect (Linux, better than auto_route for servers). 推荐在 Linux 上始终启用，性能优于 tproxy，避免 TUN 与 Docker 网桥冲突。

## Mixed Inbound

```json
{
  "type": "mixed",
  "tag": "mixed-in",
  "listen": "127.0.0.1",
  "listen_port": 2080,
  "users": [{"username": "", "password": ""}],
  "set_system_proxy": false
}
```

Combined HTTP + SOCKS5 proxy. `set_system_proxy` 各平台实现：
- **macOS**: 调用 `networksetup` 设置 web/secure web/SOCKS 代理（普通用户即可，无需 root；监听网络接口变化自动更新）
- **Windows**: 通过 WinINet API 设置系统代理
- **Linux (GNOME/KDE)**: 通过 `gsettings`（GNOME）或 `kwriteconfig5/6`（KDE）设置。以 root 运行时需要 `SUDO_USER` 环境变量来切换到真实用户执行。不支持无桌面环境的服务器。
- **Android**: 需要 root、system (adb) 或 rish 权限，通过 `settings put global http_proxy` 设置
- **其他平台**: 不支持

## Outbound Types

### Proxy Protocols (Summary)
| Type | Key Fields | Notes |
|------|-----------|-------|
| `vless` | `server`, `server_port`, `uuid`, `flow`, `tls`, `transport` | `flow: "xtls-rprx-vision"` for XTLS |
| `vmess` | `server`, `server_port`, `uuid`, `security`, `tls`, `transport` | `alter_id`, `packet_encoding` |
| `shadowsocks` | `server`, `server_port`, `method`, `password` | `plugin`, `multiplex` |
| `trojan` | `server`, `server_port`, `password`, `tls`, `transport` | `multiplex` |
| `hysteria2` | `server`, `server_port`, `password`, `tls` | `obfs`, `up_mbps`, `down_mbps` |
| `hysteria` | `server`, `server_port`, `auth_string`, `tls` | legacy; prefer hysteria2 |
| `tuic` | `server`, `server_port`, `uuid`, `password`, `tls` | `congestion_control` |
| `shadowtls` | `server`, `server_port`, `version`, `password`, `tls` | must chain via `detour` |
| `anytls` | `server`, `server_port`, `password`, `tls` | padding_scheme |
| `http` | `server`, `server_port` | `username`, `password`, `tls` |
| `socks` | `server`, `server_port` | `version`, `username`, `password` |
| `ssh` | `server`, `server_port`, `user` | `private_key`, `password` |

### Proxy Protocol Details

**Hysteria2:**
```json
{
  "type": "hysteria2",
  "tag": "hy2-out",
  "server": "example.com",
  "server_port": 443,
  "password": "your-password",
  "obfs": { "type": "salamander", "password": "obfs-password" },
  "up_mbps": 100, "down_mbps": 200,
  "tls": { "enabled": true, "server_name": "example.com" }
}
```
- `server_ports` ([]string): port hopping, e.g. `["1000:2000", "3000"]`
- `hop_interval` (Duration): port hop interval, default `30s`

**TUIC:**
```json
{
  "type": "tuic",
  "tag": "tuic-out",
  "server": "example.com",
  "server_port": 443,
  "uuid": "your-uuid",
  "password": "your-password",
  "congestion_control": "bbr",
  "udp_relay_mode": "native",
  "zero_rtt_handshake": true,
  "tls": { "enabled": true, "server_name": "example.com", "alpn": ["h3"] }
}
```
- `congestion_control`: `cubic` (default), `bbr`, `new_reno`
- `udp_relay_mode`: `native` (default), `quic`

**ShadowTLS:**
```json
{
  "type": "shadowtls",
  "tag": "st-out",
  "server": "example.com",
  "server_port": 443,
  "version": 3,
  "password": "your-password",
  "tls": { "enabled": true, "server_name": "www.microsoft.com", "utls": { "enabled": true, "fingerprint": "chrome" } }
}
```
ShadowTLS wraps another protocol. Chain with inner outbound:
```json
{ "type": "shadowsocks", "tag": "ss-inner", "method": "2022-blake3-aes-128-gcm", "password": "...", "detour": "st-out", "udp_over_tcp": { "enabled": true } }
```

**AnyTLS:**
```json
{
  "type": "anytls",
  "tag": "anytls-out",
  "server": "example.com",
  "server_port": 443,
  "password": "your-password",
  "tls": { "enabled": true, "server_name": "example.com" },
  "idle_session_check_interval": "30s",
  "idle_session_timeout": "2m",
  "min_idle_session": 2
}
```

### Special Outbounds
| Type | Fields | Notes |
|------|--------|-------|
| `direct` | - | Direct connection, supports Dial Fields |
| `selector` | `outbounds` (required), `default`, `interrupt_exist_connections` | Manual switch (Clash API) |
| `urltest` | `outbounds` (required), `url`, `interval`, `tolerance`, `idle_timeout` | Auto-select by latency |
| `dns` | - | **REMOVED in 1.13.0** → use `hijack-dns` action |
| `block` | - | **Deprecated** → use `"action": "reject"` |

### Endpoints (not outbounds — separate `endpoints` array)

**WireGuard:**
```json
{
  "type": "wireguard",
  "tag": "wg-ep",
  "address": ["10.0.0.2/32"],
  "private_key": "your-private-key",
  "peers": [{
    "server": "wg.example.com",
    "server_port": 51820,
    "public_key": "peer-public-key",
    "pre_shared_key": "optional",
    "allowed_ips": ["0.0.0.0/0"]
  }],
  "mtu": 1408,
  "workers": 2
}
```
Goes in top-level `"endpoints": [...]`, not `"outbounds"`. Routable as outbound by tag.

## Dial Fields (shared by outbounds + DNS servers)

- `detour`: Upstream outbound tag（启用后其他 dial 字段被忽略）
- `domain_resolver`: DNS server tag or `{"server": "tag", "strategy": "..."}` object（1.12.0+）
- `bind_interface`: Network interface to bind
- `inet4_bind_address` / `inet6_bind_address`: 绑定的 IPv4/IPv6 地址
- `routing_mark`: Linux netfilter 路由标记（支持整数和十六进制字符串如 `"0x1234"`）
- `reuse_addr`: 重用监听地址
- `netns`: 网络命名空间（1.12.0+，仅 Linux）
- `connect_timeout`: Connection timeout (Duration)
- `tcp_fast_open`: Enable TFO (bool)
- `tcp_multi_path`: Enable MPTCP (bool)
- `disable_tcp_keep_alive`: 禁用 TCP Keep-Alive（1.13.0+）
- `tcp_keep_alive`: Keep-Alive 初始周期（1.13.0+，默认 `5m`）
- `tcp_keep_alive_interval`: Keep-Alive 间隔（1.13.0+，默认 `75s`）
- `udp_fragment`: 启用 UDP 分片
- `network_strategy`: `default`, `hybrid`, `fallback`（1.11.0+，与 `bind_interface` 互斥）
- `network_type` / `fallback_network_type`: `wifi`, `cellular`, `ethernet`, `other`（1.11.0+）
- `fallback_delay`: Delay before trying fallback network（默认 `300ms`）

## Multiplex (smux/h2mux)

Multiplexes multiple connections over a single TCP stream. Supported by: shadowsocks, vmess, vless, trojan.

```json
{
  "type": "vless",
  "multiplex": {
    "enabled": true,
    "protocol": "h2mux",
    "max_connections": 4,
    "min_streams": 4,
    "max_streams": 0,
    "padding": true,
    "brutal": { "enabled": true, "up_mbps": 50, "down_mbps": 100 }
  }
}
```
- `protocol`: `smux`, `yamux`, `h2mux`（默认 `h2mux`）
- `brutal`: TCP Brutal congestion control (requires server support)
- `padding`: randomize packet sizes to resist traffic analysis
- `max_connections` 与 `max_streams` 互斥；`min_streams` 与 `max_streams` 互斥

## UDP over TCP

Wrap UDP in TCP for protocols/networks that don't support UDP. Supported by: shadowsocks, socks.

```json
{ "udp_over_tcp": { "enabled": true, "version": 2 } }
```

## TLS Options (outbound)

```json
{
  "enabled": true,
  "server_name": "example.com",
  "insecure": false,
  "alpn": ["h2", "http/1.1"],
  "min_version": "1.2",
  "utls": { "enabled": true, "fingerprint": "chrome" },
  "reality": { "enabled": true, "public_key": "...", "short_id": "..." },
  "ech": { "enabled": true, "config": ["base64-ech-config"] },
  "fragment": true,
  "fragment_fallback_delay": "500ms",
  "record_fragment": true
}
```

### ECH (Encrypted Client Hello)
Encrypts SNI to prevent middlebox detection. Two modes:
- **Static config**: `"config": ["base64-encoded-ECHConfigList"]`
- **DNS query**: `"config_path": "file.pem"` or omit config to query DNS HTTPS record via `"query_server_name": "dns.example.com"`

### TLS Fragment
Splits TLS ClientHello into small fragments to bypass DPI:
- `"fragment": true` on TLS options: fragment the TLS handshake
- `"fragment_fallback_delay"`: time before fallback to unfragmented (default `"500ms"`，源码 `constant/timeout.go`)
- `"record_fragment": true`: also fragment TLS records (more aggressive)
- **`fragment` 和 `record_fragment` 互斥**，不能同时开启

Can also be set per-route via route-options action:
```json
{ "action": "route-options", "tls_fragment": true, "tls_fragment_fallback_delay": "500ms" }
```
注意：route-options 中 `tls_fragment` 是 bool 类型（不是对象），`tls_record_fragment` 也是 bool。两者同样互斥。

### uTLS Fingerprints
Available: `chrome`, `firefox`, `edge`, `safari`, `360`, `qq`, `ios`, `android`, `random`, `randomized`

## V2Ray Transport Options

| Type | Key Fields |
|------|-----------|
| `http` | `host` ([]string), `path`, `method`, `headers`, `idle_timeout`, `ping_timeout` |
| `ws` | `path`, `headers`, `max_early_data`, `early_data_header_name` |
| `grpc` | `service_name`, `idle_timeout`, `ping_timeout`, `permit_without_stream` |
| `httpupgrade` | `host`, `path`, `headers` |
| `quic` | (no additional fields, requires QUIC TLS) |

## Rule-Set

```json
{
  "type": "remote",
  "tag": "geosite-cn",
  "format": "binary",
  "url": "https://testingcf.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-cn.srs",
  "download_detour": "direct",
  "update_interval": "1d"
}
```

Formats: `source` (JSON, larger) or `binary` (SRS, smaller+faster).
Types: `remote` (URL download), `local` (file path), `inline` (embedded rules).

## Experimental

### Cache File
```json
{
  "enabled": true,
  "store_fakeip": true,
  "store_rdrc": true,
  "rdrc_timeout": "7d"
}
```
- `store_fakeip`: 持久化 fakeip 映射，重启后不丢失（否则报 "missing fakeip record"）
- `store_rdrc`: 持久化 DNS 响应过滤的拒绝结果缓存（RDRC = Rejected DNS Response Cache）。当 DNS 规则中的响应过滤字段（`ip_cidr`、`ip_is_private`、`ip_accept_any`）拒绝了某个 DNS 响应时，这个拒绝结果会被缓存。下次相同查询直接返回拒绝，跳过实际 DNS 请求。在分流场景中，这避免了重复向错误的 DNS 服务器发送查询（如国内 DNS 解析被污染的海外域名），提升性能。
- `rdrc_timeout`: 拒绝缓存过期时间，默认 `"7d"`
- `cache_id`: 隔离多配置间的缓存数据

### Clash API
```json
{
  "external_controller": "127.0.0.1:9090",
  "external_ui": "ui",
  "secret": "",
  "default_mode": "rule"
}
```

## Route Top-Level Fields

```json
{
  "route": {
    "rules": [],
    "rule_set": [],
    "final": "proxy",
    "auto_detect_interface": true,
    "default_domain_resolver": "local-dns"
  }
}
```

- `final`: Default outbound when no rule matches
- `auto_detect_interface`: Bind to default interface (prevents TUN routing loops)
- `default_domain_resolver`: DNS server for resolving domain-based outbound addresses

## DNS Top-Level Fields

```json
{
  "dns": {
    "servers": [],
    "rules": [],
    "final": "google-dns",
    "strategy": "ipv4_only",
    "independent_cache": true
  }
}
```

- `final`: Default DNS server when no rule matches
- `strategy`: `prefer_ipv4`, `prefer_ipv6`, `ipv4_only`, `ipv6_only`
- `independent_cache`: Per-server DNS cache (prevents cross-contamination)

## Route-Options Action Fields

Non-final action that sets per-connection options without selecting an outbound:
```json
{
  "action": "route-options",
  "override_address": "1.2.3.4",
  "override_port": 443,
  "network_strategy": "hybrid",
  "fallback_delay": "300ms",
  "udp_disable_domain_unmapping": false,
  "udp_connect": true,
  "udp_timeout": "5m",
  "tls_fragment": true,
  "tls_fragment_fallback_delay": "500ms",
  "tls_record_fragment": true
}
```
- `tls_fragment` 和 `tls_record_fragment` 是 **bool** 类型，且**互斥**
- `tls_fragment_fallback_delay`: 分片连接失败回退延迟（默认 `500ms`）
- `udp_disable_domain_unmapping`: 不在 UDP 响应中发送映射域名
- `udp_timeout`: 连接超时（DNS/NTP/STUN 默认 10s，QUIC/DTLS 默认 30s）

## NTP

```json
{
  "ntp": {
    "enabled": true,
    "server": "time.apple.com",
    "server_port": 123,
    "interval": "30m",
    "write_to_system": false
  }
}
```
Useful for TLS certificate validation when system clock is unreliable (embedded devices).

## Certificate

```json
{
  "certificate": {
    "store": "system",
    "certificate": [],
    "certificate_path": []
  }
}
```
- `store`: `system` (default), `mozilla`, `chrome`, `none`
- Custom CA certificates for self-signed proxy servers

## TUN Platform Options

### platform.http_proxy（图形客户端专用）

`platform` 是由图形客户端（SFM/SFA/SFI）提供的平台特定设置，命令行 `sing-box run` 会忽略此块。

在 TUN (VPN) 内部通过 Network Extension / VPN API 设置系统 HTTP 代理。与 mixed inbound 的 `set_system_proxy` 不同 — 这里不调用 `networksetup`，而是通过 VPN 隧道内部的 API 设置（Apple: `NEProxySettings`）。

```json
{
  "type": "tun",
  "platform": {
    "http_proxy": {
      "enabled": true,
      "server": "127.0.0.1",
      "server_port": 2080,
      "bypass_domain": ["localhost", "internal.corp.com"],
      "match_domain": ["specific-app.com"]
    }
  }
}
```

| 字段 | 说明 |
|------|------|
| `enabled` | 启用系统 HTTP 代理（默认 `false`） |
| `server` | 代理服务器地址（通常 `127.0.0.1`，需配合 mixed inbound 监听） |
| `server_port` | 代理服务器端口 |
| `bypass_domain` | 绕过代理的域名。**Apple 平台匹配后缀**（`example.com` 会匹配 `api.example.com`） |
| `match_domain` | 使用代理的域名。**仅 Apple 图形客户端支持**，其他平台忽略 |

**注意：** HTTP 和 HTTPS 使用同一个代理服务器（Apple 实现中 `httpServer` 和 `httpsServer` 指向同一地址）。

### macOS TUN 权限模型

| 方式 | 权限 | 说明 |
|------|------|------|
| **SFM 图形客户端** | 无需 root（Network Extension） | Apple 开发者 entitlement `packet-tunnel-provider`，系统内核创建 TUN 设备 |
| **SFM.System 独立模式** | 无需 root（System Extension） | 需用户在系统设置中批准安装，运行在 app 沙盒外 |
| **命令行 `sing-box run`** | 需要 **sudo** | 直接通过 `com.apple.net.utun_control` socket 创建 utun 设备 |

### Android 分应用代理

```json
{
  "type": "tun",
  "include_package": ["com.android.chrome"],
  "exclude_package": ["com.tencent.mm"]
}
```
- `include_package` / `exclude_package`: Android per-app proxy（包名）
- `include_uid` / `exclude_uid` / `include_uid_range` / `exclude_uid_range`: Linux UID-based filtering
- `route_address` / `route_exclude_address`: IP-based split tunneling
