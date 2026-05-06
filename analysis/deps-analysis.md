# OpenWRT-CI 依赖分析报告

> 生成时间: 2026-05-06
> 分析范围: fix-dependencies.sh (18项修复) + feeds.yml (7个源) + 170+ _plugin.yml

---

## 目录

1. [fix-dependencies.sh 现有修复的问题](#1-fix-dependenciessh-现有修复的问题)
2. [遗漏的依赖问题](#2-遗漏的依赖问题)
3. [第三方源冲突分析](#3-第三方源冲突分析)
4. [_plugin.yml 声明依赖问题](#4-_pluginyml-声明依赖问题)
5. [已知编译失败包](#5-已知编译失败包)
6. [建议新增的修复代码](#6-建议新增的修复代码)

---

## 1. fix-dependencies.sh 现有修复的问题

### 🔴 [严重] Bug #1: kismet libpcre → libpcre2 的 sed 模式会二次破坏

**问题**: 脚本执行两步替换：
```bash
fix_dep "$KISMET_DIR/Makefile" "+libpcre" "+libpcre2"
fix_dep "$KISMET_DIR/Makefile" "libpcre" "libpcre2"
```

第二步 `sed "s/libpcre/libpcre2/g"` 会将第一步已经生成的 `libpcre2` 变为 `libpcre22`，导致依赖完全错误。

**修复**: 第二步应使用边界匹配，或改为更精确的模式：

```bash
# 修复方案：先处理带 + 前缀的，再用边界匹配处理独立引用
fix_dep "$KISMET_DIR/Makefile" "+libpcre" "+libpcre2"
# 使用 word boundary 避免二次替换
sed -i 's/\blibpcre\b/libpcre2/g' "$KISMET_DIR/Makefile"
# 或者更安全：仅替换不以 2 结尾的 libpcre
sed -i 's/libpcre\([^2]\)/libpcre2\1/g; s/libpcre$/libpcre2/' "$KISMET_DIR/Makefile"
```

**影响**: 如果 Makefile 中已有 `libpcre2` 引用，编译必然失败。

---

### 🟡 [中等] Bug #2: trojan-plus boost-system → boost 过于简单

**问题**: 现代 OpenWrt 的 boost 包已拆分为多个子包（boost-system、boost-program-options、boost-filesystem 等）。简单替换为 `boost` 可能导致：
- 编译时找不到具体子库的头文件
- 链接时缺少具体的 .so 文件

**修复**: 应根据 trojan-plus 实际使用的 boost 子库来决定：

```bash
# 先检查 trojan-plus 的 CMakeLists.txt 或 configure 脚本
# 确认使用了哪些 boost 组件，然后替换为对应的包名
# 例如如果只需要 system 和 program_options：
fix_dep "$TROJAN_DIR/Makefile" "boost-system" "+boost-libs"
# 或保留 boost-system 如果它存在于当前 feed 版本
```

---

### 🟡 [中等] Bug #3: luci-app-ssrust 的 shadowsocks-rust-config 检查存在竞态

**问题**: 脚本用 `find_pkg_dir "shadowsocks-rust"` 判断是否存在，但 `shadowsocks-rust-config` 可能是 `shadowsocks-rust` 的子包（`PACKAGE_shadowsocks-rust-config`），即使主包目录不存在，子包也可能通过其他方式提供。

**修复**: 应直接检查 feeds 中是否有 `shadowsocks-rust-config` 的定义：

```bash
# 更可靠的检查方式
if ! grep -rq "Package/shadowsocks-rust-config" package/feeds/*/shadowsocks-rust/ 2>/dev/null; then
  remove_dep "$SSRUST_DIR/Makefile" "shadowsocks-rust-config"
fi
```

---

### 🟢 [建议] Issue #4: 修复 14 (webd) 注释说"可能编译失败"但未处理

**问题**: 注释提到 webd 存在于 kiddin4 但可能编译失败，建议条件编译但最终"不修改"。

**修复**: 建议添加编译失败时的 fallback：

```bash
# 修复 14: luci-app-webd — webd 可能编译失败
WEBD_DIR=$(find_pkg_dir "luci-app-webd" || true)
if [ -n "$WEBD_DIR" ]; then
  # 检查 webd 包是否存在且可用
  WEBD_PKG=$(find_pkg_dir "webd" || true)
  if [ -z "$WEBD_PKG" ]; then
    remove_dep "$WEBD_DIR/Makefile" "webd"
  fi
fi
```

---

### 🟢 [建议] Issue #5: 修复 18 (luci-app-school) 保留了可能编译失败的依赖

**问题**: rkp-ipid 存在于 kiddin4 但可能编译失败，脚本选择"保留依赖，不修改"。

**修复**: 建议同样做条件检查：

```bash
SCHOOL_DIR=$(find_pkg_dir "luci-app-school" || true)
if [ -n "$SCHOOL_DIR" ]; then
  RKP_DIR=$(find_pkg_dir "rkp-ipid" || true)
  if [ -z "$RKP_DIR" ]; then
    remove_dep "$SCHOOL_DIR/Makefile" "rkp-ipid"
  fi
fi
```

---

## 2. 遗漏的依赖问题

### 🔴 [严重] 遗漏 #1: libpcre → libpcre2 迁移不止 kismet 一个包

**背景**: OpenWrt 主线已移除 `libpcre`，全面迁移到 `libpcre2`。以下第三方包可能仍依赖 `libpcre`：

| 包名 | 来源 | 说明 |
|------|------|------|
| aircrack-ng | kiddin4/kenzo | 无线安全工具 |
| nmap | kiddin4 | 网络扫描 |
| snort | kiddin4 | 入侵检测 |
| kismet | 已修复 | — |
| libpcre 相关的其他工具 | kiddin4 | 需全面扫描 |

**修复代码**:

```bash
# 全局扫描所有 feeds 中引用 libpcre 的 Makefile（排除 libpcre2 自身）
echo "  🔍 扫描 libpcre 残留引用..."
for makefile in $(grep -rl "libpcre[^2]" package/feeds/*/Makefile 2>/dev/null); do
  pkg_dir=$(dirname "$makefile")
  pkg_name=$(basename "$pkg_dir")
  # 排除 libpcre2 包自身
  if [[ "$pkg_name" != "libpcre2" && "$pkg_name" != "pcre2" ]]; then
    fix_dep "$makefile" "+libpcre" "+libpcre2"
    # 精确替换 libpcre（不匹配 libpcre2）
    sed -i 's/libpcre\([^2]\)/libpcre2\1/g; s/libpcre$/libpcre2/' "$makefile"
  fi
done
```

---

### 🔴 [严重] 遗漏 #2: kmod-nf-conntrack6 合并问题不止 jool/openvswitch

**背景**: Linux 内核 5.15+ 将 IPv4/IPv6 conntrack 合并为单一 `nf_conntrack` 模块，`kmod-nf-conntrack6` 已不存在。

**可能受影响的包**（来源: kiddin4/kenzo）:

| 包名 | 说明 |
|------|------|
| jool | 已修复 |
| openvswitch | 已修复 |
| kmod-conntrack-extra | 可能引用旧模块名 |
| iptables-nft 相关包 | 可能有残留依赖 |
| pbr (policy-based routing) | 可能引用 conntrack6 |
| mwan3 | 多 WAN 负载均衡 |
| luci-app-turboacc | 网络加速 |
| oaf (应用过滤) | 可能需要 conntrack |

**修复代码**:

```bash
# 全局扫描 kmod-nf-conntrack6 引用
echo "  🔍 扫描 kmod-nf-conntrack6 残留引用..."
for makefile in $(grep -rl "kmod-nf-conntrack6" package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  echo "  ⚠️  $pkg_name 仍引用 kmod-nf-conntrack6，移除中..."
  remove_dep "$makefile" "kmod-nf-conntrack6"
done
```

---

### 🔴 [严重] 遗漏 #3: python3 包名变更未处理

**背景**: OpenWrt 23.05+ 将多个 python3 子包重命名：
- `python3-pysocks` → 已移除或合并到 `python3-socks`
- `python3-unidecode` → 可能不再单独打包
- `python3-crypto` → `python3-pycryptodome`
- `python3-pyopenssl` → 可能改名

**当前处理**: 仅移除了 onionshare-cli 的两个 python3 依赖，但可能有其他包受影响。

**修复代码**:

```bash
# 扫描已知变更的 python3 包名
echo "  🔍 扫描 python3 包名变更..."
declare -A PY_RENAMES=(
  ["python3-pysocks"]="python3-socks"
  ["python3-crypto"]="python3-pycryptodome"
)

for old_pkg in "${!PY_RENAMES[@]}"; do
  new_pkg="${PY_RENAMES[$old_pkg]}"
  for makefile in $(grep -rl "$old_pkg" package/feeds/*/Makefile 2>/dev/null); do
    pkg_name=$(basename "$(dirname "$makefile")")
    echo "  ⚠️  $pkg_name 引用 $old_pkg，替换为 $new_pkg..."
    fix_dep "$makefile" "$old_pkg" "$new_pkg"
  done
done
```

---

### 🟡 [中等] 遗漏 #4: wolfssl 兼容性问题

**背景**: wolfssl 在 OpenWrt 中经历了多次重命名和 API 变更：
- `libwolfssl` vs `wolfssl` 包名
- wolfssl 5.x → 6.x API 变更导致部分包编译失败

**可能受影响的包**: 使用 TLS 的第三方包（在 kiddin4/kenzo 中）

**修复代码**:

```bash
# 检查 wolfssl 兼容性
echo "  🔍 检查 wolfssl 兼容性..."
for makefile in $(grep -rl "wolfssl" package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  # 检查是否使用了已废弃的 wolfssl 包名
  if grep -q "+wolfssl\b" "$makefile" 2>/dev/null; then
    echo "  ⚠️  $pkg_name 使用 wolfssl，可能需要更新为 libwolfssl"
  fi
done
```

---

### 🟡 [中等] 遗漏 #5: boost 子包拆分问题

**背景**: OpenWrt 的 boost 包在 1.81+ 版本进行了子包拆分：
- `boost-system` → `boost-system`（保留但可能重命名）
- `boost-program-options` → `boost-program-options`
- `boost-filesystem` → `boost-filesystem`
- 总包 `boost` → `boost-libs` + `boost-headers`

**当前处理**: 仅修复了 trojan-plus，但可能有其他包受影响。

**修复代码**:

```bash
# 扫描 boost 子包引用
echo "  🔍 扫描 boost 子包引用..."
BOOST_SUBS=("boost-system" "boost-program-options" "boost-filesystem" "boost-thread" "boost-regex")
for sub in "${BOOST_SUBS[@]}"; do
  for makefile in $(grep -rl "+${sub}" package/feeds/*/Makefile 2>/dev/null); do
    pkg_name=$(basename "$(dirname "$makefile")")
    # 检查该子包是否实际存在
    if ! find package/feeds -name "Makefile" -path "*/boost/*" -exec grep -l "Package/${sub}" {} \; 2>/dev/null | head -1 | grep -q .; then
      echo "  ⚠️  $pkg_name 依赖 $sub，但该子包可能不存在"
    fi
  done
done
```

---

### 🟡 [中等] 遗漏 #6: iptables → nftables 迁移残留

**背景**: OpenWrt 23.05+ 默认使用 nftables，但部分第三方包仍硬编码 iptables 依赖。

**可能受影响的包**:

| 包名 | 说明 |
|------|------|
| luci-app-openclash | 声明依赖 ipset（nft 模式下不同） |
| luci-app-passwall | firewall: 1，可能有 iptables 依赖 |
| luci-app-turboacc | SFE/Flow Offload 可能需要 iptables |
| luci-app-syncdial | 多拨可能依赖 iptables 规则 |
| luci-app-appfilter | 应用过滤依赖 iptables |

**修复代码**:

```bash
# 检查 iptables 硬编码依赖
echo "  🔍 检查 iptables 兼容性..."
for makefile in $(grep -rl "+iptables\b" package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  echo "  ℹ️  $pkg_name 依赖 iptables，确认 nftables 兼容性"
done
```

---

### 🟢 [建议] 遗漏 #7: kmod-shortcut-fe / kmod-fast-classifier 内核兼容性

**背景**: `luci-app-turboacc` 声明依赖 `kmod-fast-classifier` 和 `kmod-shortcut-fe`，这两个内核模块在新版内核上可能无法编译。

**影响**: luci-app-turboacc 在内核 6.x 上可能无法使用 SFE 加速。

**建议**: 标记为可选依赖或在编译失败时自动跳过。

---

## 3. 第三方源冲突分析

### 🔴 [严重] 冲突 #1: kenzo 与 kiddin4 大量包重叠

**分析**: kenzo 和 kiddin4 都是大型第三方源，提供大量相同功能的包。当两者同时启用时：

| 冲突包组 | kenzo 提供 | kiddin4 提供 | 风险 |
|----------|-----------|-------------|------|
| luci-app-passwall | ✅ | ✅ | Makefile 冲突 |
| luci-app-openclash | ✅ | ✅ | 版本不一致 |
| luci-app-v2raya | ✅ | ✅ | 依赖可能不同 |
| luci-app-ssrust | ✅ | ✅ | 编译选项差异 |
| luci-app-dockerman | ✅ (主源) | ✅ | API 不兼容 |
| luci-app-unblockneteasemusic | ✅ (主源) | ✅ | node 版本差异 |
| xray-core / sing-box | ✅ (small) | ✅ | 版本不同步 |

**问题**: OpenWrt 的 feeds 系统按优先级处理包定义。如果 kenzo 和 kiddin4 同时定义了 `luci-app-passwall`，只有一个会被使用，但其依赖可能指向另一个源的包，导致依赖解析失败。

**修复建议**:
1. **优先使用 kenzo/small 组合**（同一作者维护，一致性好）
2. **kiddin4 仅用于 kenzo 中不存在的包**
3. 或者反过来，但不要混用

---

### 🟡 [中等] 冲突 #2: kenzo 与 small 的版本同步风险

**分析**: kenzo 和 small 来自同一作者 (kenzok8)，small 是精简依赖源。但：
- 两个仓库可能更新不同步
- passwall 声明同时依赖 small 和 kenzo，如果版本不匹配可能出问题

**建议**: 在 CI 中固定两个仓库的 commit hash，确保版本一致：

```yaml
# feeds.yml 建议
kenzo:
  url: https://github.com/kenzok8/openwrt-packages
  branch: master
  # pin: <commit-hash>  # 固定版本

small:
  url: https://github.com/kenzok8/small
  branch: master
  # pin: <commit-hash>  # 与 kenzo 同一时间点的提交
```

---

### 🟡 [中等] 冲突 #3: kiddin4 的 luci-theme 与官方 luci 重叠

**分析**: kiddin4 提供了多个 luci-theme（bootstrap、openwrt 等），但这些主题在官方 luci feed 中已存在。可能导致：
- 主题文件覆盖
- JavaScript/CSS 资源冲突
- LuCI 版本不兼容

**受影响的主题**:
- `luci-theme-bootstrap`（官方已有）
- `luci-theme-openwrt`（官方已有）
- `luci-theme-material`（可能与官方冲突）

**建议**: 从 kiddin4 中排除官方已有的主题，或确保 kiddin4 的版本优先级低于官方。

---

## 4. _plugin.yml 声明依赖问题

### 🔴 [严重] 问题 #1: luci-app-turboacc 依赖可能不存在的内核模块

```yaml
# network/luci-app-turboacc/_plugin.yml
deps:
  - kmod-fast-classifier
  - kmod-shortcut-fe
```

`kmod-fast-classifier` 和 `kmod-shortcut-fe` 在新版 OpenWrt/内核上可能无法编译，且不在标准 feeds 中。

**修复**: 标记为可选或添加条件检查。

---

### 🔴 [严重] 问题 #2: luci-app-dockerman 依赖 luci-lib-docker

```yaml
# docker/luci-app-dockerman/_plugin.yml
deps:
  - docker
  - dockerd
  - luci-lib-docker
```

`luci-lib-docker` 是 kenzo 源的包，如果 dockerman 来自 kiddin4 而 luci-lib-docker 来自 kenzo，版本可能不兼容。

**注意**: 该插件 source 标记为 `kenzo`，但 deps 中 `luci-lib-docker` 需确认是否在 kenzo 中存在。

---

### 🟡 [中等] 问题 #3: luci-app-unblockneteasemusic 依赖 node

```yaml
# multimedia/luci-app-unblockneteasemusic/_plugin.yml
deps:
  - node
```

**问题**:
- `node`（Node.js）编译极其耗时（通常 30-60 分钟），且在低内存设备上可能编译失败
- 大多数路由器不适合运行 Node.js 应用

**建议**: 标记为"大依赖"警告，或提供跳过选项。

---

### 🟡 [中等] 问题 #4: luci-app-passwall 依赖链过深

```yaml
# proxy/luci-app-passwall/_plugin.yml
deps:
  - chinadns-ng
  - dns2socks
  - dns2tcp
  - hysteria
  - ipt2socks
  - iptables
  - lua-neturl
  - microsocks
  - naive-proxy
  - redsocks2
  - shadowsocks-libev-ss-local
  - shadowsocks-libev-ss-redir
  - shadowsocks-rust-sslocal
  - simple-obfs
  - sing-box
  - tcping
  - trojan
  - trojan-go
  - tuic-client
  - v2ray-core
  - v2ray-plugin
  - xray-core
```

**问题**: 22 个依赖，其中多个来自 small/kenzo 源。如果任何一环缺失或版本不兼容，整个 passwall 编译失败。

**建议**: 将依赖分为"必需"和"可选"两组，允许用户选择性安装。

---

### 🟢 [建议] 问题 #5: 部分插件 deps 声明为空但实际有依赖

**分析**: 大量 kiddin4 来源的插件 `deps: []` 为空。这可能意味着：
1. 依赖在 Makefile 中硬编码（不在 yml 中声明）
2. 确实无依赖
3. **依赖声明遗漏**

**高风险插件**（deps 为空但功能上明显需要依赖）:

| 插件 | 预期依赖 | 风险 |
|------|----------|------|
| luci-app-docker | docker, dockerd | 高 |
| luci-app-syncthing | syncthing | 高 |
| luci-app-qbittorrent | qbittorrent-nox | 高 |
| luci-app-transmission | transmission-daemon | 高 |
| luci-app-aria2 | aria2 | 高 |
| luci-app-clamav | clamav | 高 |
| luci-app-netdata (非 openwrt 源) | netdata | 中 |
| luci-app-snmpd | snmpd | 中 |
| luci-app-vnstat2 | vnstat2 | 中 |
| luci-app-tor | tor | 中 |
| luci-app-zerotier | zerotier | 中 |

**建议**: 这些包的依赖可能在 Makefile 中定义。如果 yml 的 `deps` 字段用于 CI 预检查，则需要补充。

---

## 5. 已知编译失败包

### 🔴 [严重] 高概率编译失败

| 包名 | 来源 | 原因 | 建议 |
|------|------|------|------|
| kmod-shortcut-fe | feeds | 内核 6.x 不兼容 | 排除或条件编译 |
| kmod-fast-classifier | feeds | 内核 6.x 不兼容 | 排除或条件编译 |
| luci-app-k3screenctrl | kiddin4 | 仅适配 Phicomm K3 硬件 | 排除 |
| luci-app-broadbandacc | kiddin4 | 功能可疑，可能无法编译 | 排除 |

### 🟡 [中等] 中等概率编译失败

| 包名 | 来源 | 原因 | 建议 |
|------|------|------|------|
| luci-app-homeassistant | kiddin4 | 依赖 Python 生态，ARM 上常失败 | 标记大依赖 |
| luci-app-xunyou | kiddin4 | 闭源/维护不佳 | 可选排除 |
| luci-app-unblockneteasemusic | kenzo | 依赖 node，编译慢且易失败 | 标记大依赖 |
| luci-app-school | kiddin4 | rkp-ipid 依赖可能缺失 | 条件检查 |
| luci-app-webd | kiddin4 | webd 二进制可能编译失败 | 条件检查 |
| onionshare-cli | kiddin4 | Python 依赖链复杂 | 持续维护 |

### 🟢 [建议] 低概率但值得注意

| 包名 | 来源 | 原因 | 建议 |
|------|------|------|------|
| luci-app-openclash | kiddin4 | 依赖 ipset，nft 模式需注意 | 测试验证 |
| luci-app-dump1090 | kiddin4 | 依赖硬件 (SDR) | 可选 |
| luci-app-oscam | kiddin4 | 依赖智能卡硬件 | 可选 |
| luci-app-ps3netsrv | kiddin4 | 用途极窄 | 可选 |

---

## 6. 建议新增的修复代码

将以下代码追加到 `fix-dependencies.sh` 的 `# ── 汇总 ──` 之前：

```bash
# ═══════════════════════════════════════════
#  修复 19: 全局 libpcre → libpcre2 迁移
#  OpenWrt 主线已移除 libpcre
# ═══════════════════════════════════════════
echo "  🔍 全局扫描 libpcre 残留引用..."
for makefile in $(grep -rl 'libpcre[^2]' package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  # 排除 libpcre2 包自身
  if [[ "$pkg_name" != "libpcre2" && "$pkg_name" != "pcre2" ]]; then
    # 精确替换：libpcre 后面不跟 2 的情况
    if grep -q 'libpcre[^2]' "$makefile" 2>/dev/null; then
      sed -i 's/+libpcre\b/+libpcre2/g' "$makefile"
      sed -i 's/libpcre\([^2]\)/libpcre2\1/g; s/libpcre$/libpcre2/' "$makefile"
      echo "  ✅ $pkg_name: libpcre → libpcre2 (全局扫描)"
      PATCHED=$((PATCHED + 1))
    fi
  fi
done

# ═══════════════════════════════════════════
#  修复 20: 全局 kmod-nf-conntrack6 移除
#  nf_conntrack v6 已合并到 nf_conntrack
# ═══════════════════════════════════════════
echo "  🔍 全局扫描 kmod-nf-conntrack6 残留引用..."
for makefile in $(grep -rl 'kmod-nf-conntrack6' package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  remove_dep "$makefile" "kmod-nf-conntrack6"
done

# ═══════════════════════════════════════════
#  修复 21: python3 包名变更
#  处理已知的 python3 子包重命名
# ═══════════════════════════════════════════
echo "  🔍 扫描 python3 包名变更..."
for makefile in $(grep -rl 'python3-pysocks' package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  # python3-pysocks 已不存在，移除
  remove_dep "$makefile" "python3-pysocks"
done

for makefile in $(grep -rl 'python3-crypto\b' package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  fix_dep "$makefile" "python3-crypto" "python3-pycryptodome"
done

# ═══════════════════════════════════════════
#  修复 22: boost 子包兼容性
#  确保 boost 引用使用正确的包名
# ═══════════════════════════════════════════
echo "  🔍 检查 boost 子包兼容性..."
for makefile in $(grep -rl '+boost-system\b' package/feeds/*/Makefile 2>/dev/null); do
  pkg_name=$(basename "$(dirname "$makefile")")
  # 如果 boost-system 作为独立包不存在，替换为 boost-libs
  BOOST_SYS_DIR=$(find_pkg_dir "boost-system" || true)
  if [ -z "$BOOST_SYS_DIR" ]; then
    fix_dep "$makefile" "boost-system" "boost-libs"
  fi
done

# ═══════════════════════════════════════════
#  修复 23: luci-app-ssrust 条件检查修复
#  更精确地检查 shadowsocks-rust-config
# ═══════════════════════════════════════════
SSRUST_DIR=$(find_pkg_dir "luci-app-ssrust" || true)
if [ -n "$SSRUST_DIR" ]; then
  # 直接检查 Makefile 中是否有 shadowsocks-rust-config 的 Package 定义
  SSR_CONFIG_EXISTS=false
  for d in package/feeds/*/shadowsocks-rust; do
    if [ -d "$d" ] && grep -q 'Package/shadowsocks-rust-config' "$d/Makefile" 2>/dev/null; then
      SSR_CONFIG_EXISTS=true
      break
    fi
  done
  if [ "$SSR_CONFIG_EXISTS" = false ]; then
    remove_dep "$SSRUST_DIR/Makefile" "shadowsocks-rust-config"
  fi
fi

# ═══════════════════════════════════════════
#  修复 24: 修复 kismet 的 libpcre 替换 bug
#  使用精确匹配避免 libpcre2 → libpcre22
# ═══════════════════════════════════════════
KISMET_DIR=$(find_pkg_dir "kismet" || true)
if [ -n "$KISMET_DIR" ]; then
  if [ -f "$KISMET_DIR/Makefile" ]; then
    # 先检查是否已被错误替换为 libpcre22
    if grep -q 'libpcre22' "$KISMET_DIR/Makefile" 2>/dev/null; then
      sed -i 's/libpcre22/libpcre2/g' "$KISMET_DIR/Makefile"
      echo "  ✅ kismet: 修复 libpcre22 → libpcre2"
      PATCHED=$((PATCHED + 1))
    fi
    # 确保正确的 libpcre2 引用
    sed -i 's/+libpcre\b/+libpcre2/g' "$KISMET_DIR/Makefile"
    sed -i 's/libpcre\([^2]\)/libpcre2\1/g; s/libpcre$/libpcre2/' "$KISMET_DIR/Makefile"
  fi
fi
```

---

## 附录：修复优先级总结

### 🔴 严重（必须立即修复）
1. kismet libpcre → libpcre2 的 sed 二次破坏 bug
2. 全局 libpcre → libpcre2 迁移（遗漏多个包）
3. 全局 kmod-nf-conntrack6 残留扫描
4. kenzo 与 kiddin4 包重叠冲突
5. python3 包名变更遗漏

### 🟡 中等（建议尽快修复）
6. trojan-plus boost-system 替换精度
7. wolfssl 兼容性检查
8. iptables → nftables 迁移残留
9. kiddin4 luci-theme 与官方重叠
10. kenzo/small 版本同步

### 🟢 建议（优化改进）
11. luci-app-webd 条件检查
12. luci-app-school 条件检查
13. luci-app-ssrust 精确检查
14. 插件 deps 为空的补全
15. 大依赖警告机制（node、python 生态）
16. 已知编译失败包排除列表

---

*报告结束。建议按优先级逐步实施修复，并在每次修改后运行完整编译测试验证。*
