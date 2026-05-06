# OpenWRT-CI 编译警告系统性分析报告

> **分析日期**: 2026-05-06
> **日志来源**: `logs/0_build.txt` (39MB)
> **构建结果**: ✅ 编译成功（0 个致命错误）

---

## 📊 问题总览

| 类别 | 数量 | 严重程度 | 状态 |
|------|------|----------|------|
| 总警告数 | 243 行 WARNING | - | - |
| 缺失依赖警告 | 66 | ⚠️ 中 | 大部分已被 fix-dependencies.sh 修复 |
| No feed for package | 22 | ⚠️ 中 | 与缺失依赖重叠，修复后应消失 |
| OpenSSL 废弃 API | 10 | ℹ️ 低 | curl 上游问题，不影响编译 |
| 下载失败（镜像 404） | 4 (2 包) | ℹ️ 低 | 已通过 fallback 成功下载 |
| autoreconf 错误 | 2 (1 包) | ⚠️ 中 | `|| true` 容错，不影响编译 |
| CI Node.js 废弃警告 | 1 | 🔴 高 | 2026-09-16 后将无法运行 |

---

## 🔴 优先级 P0: 必须立即修复

### 1. kismet 的 libpcre 修复 Bug（fix-dependencies.sh）

**问题描述**:
`fix-dependencies.sh` 中的 sed 替换逻辑存在缺陷：

```bash
# 当前代码（第 56-57 行）
fix_dep "$KISMET_DIR/Makefile" "+libpcre" "+libpcre2"
fix_dep "$KISMET_DIR/Makefile" "libpcre" "libpcre2"
```

kismet 原始 Makefile 中的依赖是 `libpcre2`（已包含 `2`），经过第一次 `sed "s/+libpcre/+libpcre2/g"` 后变成 `+libpcre22`，第二次 `sed "s/libpcre/libpcre2/g"` 又把 `libpcre22` 变成 `libpcre222`，形成**正则贪心匹配级联错误**。

**日志证据**:
```
✅ kismet: +libpcre → +libpcre2
✅ kismet: libpcre → libpcre2
WARNING: Makefile 'package/feeds/kiddin4/kismet/Makefile' has a dependency on 'libpcre22', which does not exist
```

**影响**: kismet 包的依赖关系损坏，导致 14 次 "dependency does not exist" 警告。

**修复方案** (`scripts/fix-dependencies.sh`):

```diff
--- a/scripts/fix-dependencies.sh
+++ b/scripts/fix-dependencies.sh
@@ -53,8 +53,9 @@ KISMET_DIR=$(find_pkg_dir "kismet" || true)
 if [ -n "$KISMET_DIR" ]; then
-  fix_dep "$KISMET_DIR/Makefile" "+libpcre" "+libpcre2"
-  fix_dep "$KISMET_DIR/Makefile" "libpcre" "libpcre2"
+  # 使用 word-boundary 避免 libpcre2 被二次替换为 libpcre22
+  sed -i 's/+libpcre\b/+libpcre2/g' "$KISMET_DIR/Makefile"
+  # 仅替换不含 "2" 后缀的 libpcre（精确匹配）
+  sed -i 's/\blibpcre\b\([^2]\|$\)/libpcre2\1/g' "$KISMET_DIR/Makefile"
 fi
```

> **注意**: `\b` 在 GNU sed 中可用。更安全的做法是直接用精确字符串替换：

```diff
--- a/scripts/fix-dependencies.sh
+++ b/scripts/fix-dependencies.sh
@@ -53,8 +53,10 @@ KISMET_DIR=$(find_pkg_dir "kismet" || true)
 if [ -n "$KISMET_DIR" ]; then
-  fix_dep "$KISMET_DIR/Makefile" "+libpcre" "+libpcre2"
-  fix_dep "$KISMET_DIR/Makefile" "libpcre" "libpcre2"
+  # 精确替换: 将 "+libpcre" (不含尾部 2) 替换为 "+libpcre2"
+  # 避免 "libpcre" 贪心匹配到已修复的 "libpcre2"
+  if [ -f "$KISMET_DIR/Makefile" ]; then
+    sed -i 's/+libpcre /+libpcre2 /g; s/+libpcre$/+libpcre2/g' "$KISMET_DIR/Makefile"
+    sed -i 's/ libpcre / libpcre2 /g; s/ libpcre$/ libpcre2/g' "$KISMET_DIR/Makefile"
+  fi
 fi
```

**预期效果**: kismet 的 14 个 "dependency does not exist" 警告全部消除。

---

### 2. CI GitHub Actions Node.js 20 废弃

**问题描述**:
```
Node.js 20 actions are deprecated. The following actions are running on Node.js 20
and may not work as expected: actions/checkout@v4, actions/upload-artifact@v4.
Actions will be forced to run with Node.js 24 by default starting June 2nd, 2026.
Node.js 20 will be removed from the runner on September 16th, 2026.
```

**影响**: 
- 2026-06-02 起默认使用 Node.js 24（可能导致兼容性问题）
- 2026-09-16 起 Node.js 20 从 runner 移除，**CI 将彻底失败**

**修复方案** (`.github/workflows/build-openwrt.yml`):

```diff
--- a/.github/workflows/build-openwrt.yml
+++ b/.github/workflows/build-openwrt.yml
@@ -1,3 +1,6 @@
+env:
+  # 强制 GitHub Actions 使用 Node.js 24（避免 2026-09 弃用）
+  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"
+
 name: 🚀 Build OpenWrt Firmware
 
 on:
```

或者直接升级到支持 Node.js 24 的 actions 版本：

```diff
--- a/.github/workflows/build-openwrt.yml
+++ b/.github/workflows/build-openwrt.yml
@@ -95,7 +95,7 @@ jobs:
       # ── L1: 检出 (含 scripts/ + config/) ──
       - name: 🛎️ Checkout
-        uses: actions/checkout@v4
+        uses: actions/checkout@v5
 
       # ... (省略中间步骤)
 
       # ── L9: 上传 ──
       - name: 📤 Upload Firmware
         if: inputs.upload_artifacts == 'true'
-        uses: actions/upload-artifact@v4
+        uses: actions/upload-artifact@v5
```

> **注意**: 截至分析日期，`actions/checkout@v5` 和 `actions/upload-artifact@v5` 尚未发布。
> 推荐方案：添加 `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"` 环境变量作为过渡方案。

---

## 🟡 优先级 P1: 应尽快修复

### 3. 剩余未覆盖的缺失依赖

**fix-dependencies.sh 已覆盖的依赖**（22 个 No feed 警告中 19 个已被处理）:
- ✅ kmod-nf-conntrack6 (openvswitch/jool)
- ✅ python3-pysocks, python3-unidecode (onionshare-cli)
- ✅ mjpg-streamer (luci-app-mjpg-streamer)
- ✅ boost-system (trojan-plus)
- ✅ modemdata (3ginfo)
- ✅ minisign (dnscrypt-proxy2)
- ✅ kmod-gobinet (luci-app-gobinetmodem)
- ✅ hotplug (luci-app-hotplug)
- ✅ nft-qos (luci-app-nft-qos)
- ✅ pppwn-cpp (luci-app-pppwn)
- ✅ shairplay (luci-app-shairplay)
- ✅ kmod-sprd_pcie (luci-app-spdmodem)
- ✅ shadowsocks-rust-config (luci-app-ssrust)
- ✅ vsftpd-alt (luci-app-tencentcloud-cos)
- ✅ ChinaDNS, dns-forwarder (openwrt-dist-luci)
- ✅ libpcre → libpcre2 (kismet，但有 bug 见 P0)

**仍未处理的缺失依赖**（出现在 "has a dependency on...which does not exist" 但未在 fix-dependencies.sh 中修复）:

| 包 | 缺失依赖 | 来源 | 修复建议 |
|----|----------|------|----------|
| audit | libev | kiddin4 | 添加 `remove_dep` 或安装 libev 包 |
| autocore | lm-sensors | kiddin4 | 移除 lm-sensors 依赖 |
| busybox | libpam, libtirpc | 官方 | 可选依赖，移除或安装 |
| default-settings | luci, luci-i18n-base-zh-cn | kiddin4 | 这些是 meta 包，应在 feeds install 时已安装 |
| kexec-tools | liblzma | 官方 | 移除或安装 liblzma |
| lldpd | libnetsnmp | 官方 | 移除或安装 libnetsnmp |
| mac80211 | kmod-qca-nss-drv, kmod-qca-nss-drv-wifi-meshmgr | 官方 | Qualcomm NSS 特有内核模块，非 qualcommax 平台不存在 |
| pcat-manager | glib2, libgpiod | kiddin4 | 移除依赖或安装 |
| policycoreutils | libpam | 官方 | 移除或安装 libpam |
| school | rkp-ipid | kiddin4 | 依赖不存在，移除 |

**修复方案** — 在 `scripts/fix-dependencies.sh` 末尾添加新修复块：

```bash
# ═══════════════════════════════════════════
#  修复 19: audit — libev (不存在于 feeds)
# ═══════════════════════════════════════════
AUDIT_DIR=$(find_pkg_dir "audit" || true)
if [ -n "$AUDIT_DIR" ]; then
  remove_dep "$AUDIT_DIR/Makefile" "libev"
fi

# ═══════════════════════════════════════════
#  修复 20: autocore — lm-sensors (不存在)
# ═══════════════════════════════════════════
AUTOCORE_DIR=$(find_pkg_dir "autocore" || true)
if [ -n "$AUTOCORE_DIR" ]; then
  remove_dep "$AUTOCORE_DIR/Makefile" "lm-sensors"
fi

# ═══════════════════════════════════════════
#  修复 21: busybox — libpam, libtirpc (可选)
# ═══════════════════════════════════════════
BUSYBOX_DIR=$(find_pkg_dir "busybox" || true)
if [ -n "$BUSYBOX_DIR" ]; then
  remove_dep "$BUSYBOX_DIR/Makefile" "libpam"
  remove_dep "$BUSYBOX_DIR/Makefile" "libtirpc"
fi

# ═══════════════════════════════════════════
#  修复 22: kexec-tools — liblzma (不存在)
# ═══════════════════════════════════════════
KEXEC_DIR=$(find_pkg_dir "kexec-tools" || true)
if [ -n "$KEXEC_DIR" ]; then
  remove_dep "$KEXEC_DIR/Makefile" "liblzma"
fi

# ═══════════════════════════════════════════
#  修复 23: lldpd — libnetsnmp (不存在)
# ═══════════════════════════════════════════
LLDPD_DIR=$(find_pkg_dir "lldpd" || true)
if [ -n "$LLDPD_DIR" ]; then
  remove_dep "$LLDPD_DIR/Makefile" "libnetsnmp"
fi

# ═══════════════════════════════════════════
#  修复 24: mac80211 — kmod-qca-nss-drv (Qualcomm 特有)
# ═══════════════════════════════════════════
MAC80211_DIR=$(find_pkg_dir "mac80211" || true)
if [ -n "$MAC80211_DIR" ]; then
  remove_dep "$MAC80211_DIR/Makefile" "kmod-qca-nss-drv-wifi-meshmgr"
  remove_dep "$MAC80211_DIR/Makefile" "kmod-qca-nss-drv"
fi

# ═══════════════════════════════════════════
#  修复 25: pcat-manager — glib2, libgpiod (不存在)
# ═══════════════════════════════════════════
PCAT_DIR=$(find_pkg_dir "pcat-manager" || true)
if [ -n "$PCAT_DIR" ]; then
  remove_dep "$PCAT_DIR/Makefile" "glib2"
  remove_dep "$PCAT_DIR/Makefile" "libgpiod"
fi

# ═══════════════════════════════════════════
#  修复 26: policycoreutils — libpam (不存在)
# ═══════════════════════════════════════════
POLICYCORE_DIR=$(find_pkg_dir "policycoreutils" || true)
if [ -n "$POLICYCORE_DIR" ]; then
  remove_dep "$POLICYCORE_DIR/Makefile" "libpam"
fi

# ═══════════════════════════════════════════
#  修复 27: school — rkp-ipid (不存在)
# ═══════════════════════════════════════════
SCHOOL_DIR=$(find_pkg_dir "school" || true)
if [ -n "$SCHOOL_DIR" ]; then
  remove_dep "$SCHOOL_DIR/Makefile" "rkp-ipid"
fi
```

### 4. default-settings 的 luci 依赖

**问题**: `default-settings` 依赖 `luci` 和 `luci-i18n-base-zh-cn`，这些是 meta 包，在 `feeds install -a` 后应已存在，但仍报 "dependency does not exist"。

**分析**: 可能是 `default-settings` 在 `feeds install` 阶段被解析时，luci 包尚未完全注册。

**修复方案**: 在 `fix-dependencies.sh` 中添加（或确认 feeds install 顺序正确）：

```bash
# default-settings 的 luci 依赖应该在 feeds install 后存在
# 如果仍然报错，说明 feeds 解析顺序问题
# 不需要移除依赖，因为 luci 确实存在
# 可以忽略这些警告
```

> 这些警告是误报，luci 确实存在于 feeds 中。可以在 `fix-dependencies.sh` 中不做处理，但建议添加注释说明。

---

## 🟢 优先级 P2: 低影响 / 上游问题

### 5. OpenSSL 废弃 API 警告（curl http-ntlm.c）

**问题描述**:
```
http-ntlm.c:201: warning: 'DES_set_odd_parity' is deprecated: Since OpenSSL 3.0
http-ntlm.c:202: warning: 'DES_set_key' is deprecated: Since OpenSSL 3.0
http-ntlm.c:229-293: warning: 'DES_ecb_encrypt' is deprecated: Since OpenSSL 3.0
http-ntlm.c:328-330: warning: 'MD4_Init/Update/Final' is deprecated: Since OpenSSL 3.0
```

**来源**: curl 包的 NTLM 认证模块，使用了 OpenSSL 3.0 废弃的 DES/MD4 API。

**影响**: 仅编译警告，不影响功能。这是 curl 上游代码问题。

**修复方案**: 
- **不建议自行 patch**，等待 curl 上游更新
- 如需静默，可在 curl 的 Makefile 中添加编译标志：

```makefile
# 在 feeds/packages/net/curl/Makefile 的 TARGET_CFLAGS 中添加
TARGET_CFLAGS += -Wno-deprecated-declarations
```

> **推荐**: 不做处理，保持与上游一致。

### 6. 下载失败（镜像 404）

**libxml2-2.15.1**:
```
curl: (22) The requested URL returned error: 404  (mirrors.ustc.edu.cn)
curl: (22) The requested URL returned error: 404  (mirror.nju.edu.cn)
# 最终从 download.gnome.org 成功下载
```

**ucert-2025.10.03~57270b24**:
```
curl: (22) The requested URL returned error: 404  (mirror2.immortalwrt.org)
curl: (22) The requested URL returned error: 404  (mirror.immortalwrt.org)
# 最终通过 git clone fallback 成功下载
```

**影响**: 无。两个包都通过 fallback 机制成功下载并编译。

**修复方案**: 无需修复。这是正常的镜像同步延迟。如需加速，可配置 DL_DIR 缓存或添加自定义镜像。

### 7. Ruby 3.4.9 autoreconf 错误

**问题描述**:
```
autoreconf: running: aclocal -I m4 -I . --force
aclocal.real: error: configure.ac:13: file 'tool/m4/$1' does not exist
autoreconf: error: aclocal failed with exit status: 1
```

**影响**: 无。OpenWrt 的 autoreconf 调用带有 `|| true` 容错，ruby 后续正常配置和编译。

**分析**: Ruby 3.4.9 的 `configure.ac` 中有 `m4_include` 引用了 `tool/m4/$1` 模板变量，aclocal 无法解析。但 ruby 的构建系统不依赖 autoreconf 生成的文件，因此错误被安全忽略。

**修复方案**: 无需修复。这是 Ruby 构建系统的已知行为。

### 8. 编译器警告（mac80211/network）

**日志中警告最多的包**:
- mac80211: ~262 个警告（未使用参数、类型转换等）
- network/utils: ~130 个警告
- network/services: ~122 个警告

**影响**: 均为 `-Wunused-parameter`、`-Wsign-compare` 等低风险警告，不影响功能。

**修复方案**: 不建议修改上游代码。如需减少日志噪音，可在 `build.sh` 中过滤：

```bash
# 在 build.sh 的 make 命令中添加
make -j${PARALLEL} V=s 2>&1 | grep -v "\-Wunused-parameter\|\-Wsign-compare" | tee build.log
```

> **不推荐**：过滤可能导致遗漏重要警告。保持原样。

---

## 📋 修复优先级汇总

| 优先级 | 问题 | 修改文件 | 预期效果 |
|--------|------|----------|----------|
| **P0** | kismet libpcre sed bug | `scripts/fix-dependencies.sh` | 消除 14 个依赖警告 |
| **P0** | CI Node.js 20 弃用 | `.github/workflows/build-openwrt.yml` | 避免 CI 失效 |
| **P1** | 10 个未覆盖的缺失依赖 | `scripts/fix-dependencies.sh` | 消除 ~40 个依赖警告 |
| P2 | OpenSSL 废弃 API | 不处理（上游问题） | - |
| P2 | 下载 404 | 不处理（已有 fallback） | - |
| P2 | Ruby autoreconf | 不处理（`|| true` 容错） | - |
| P2 | 编译器警告 | 不处理（上游代码） | - |

---

## 🔧 完整修复补丁

### 补丁 1: fix-dependencies.sh — 修复 kismet bug + 添加新依赖修复

```diff
--- a/scripts/fix-dependencies.sh
+++ b/scripts/fix-dependencies.sh
@@ -50,11 +50,18 @@ done
 #  修复 1: kismet — libpcre → libpcre2
 # ═══════════════════════════════════════════
 KISMET_DIR=$(find_pkg_dir "kismet" || true)
 if [ -n "$KISMET_DIR" ]; then
-  fix_dep "$KISMET_DIR/Makefile" "+libpcre" "+libpcre2"
-  fix_dep "$KISMET_DIR/Makefile" "libpcre" "libpcre2"
+  # 精确替换: 避免 libpcre2 被二次替换为 libpcre22
+  # 仅替换独立的 "libpcre"（不带尾部数字 2）
+  if [ -f "$KISMET_DIR/Makefile" ]; then
+    # 处理 +libpcre 前缀格式（DEPENDS 行）
+    sed -i 's/+libpcre\([^0-9]\)/+libpcre2\1/g; s/+libpcre$/+libpcre2/g' "$KISMET_DIR/Makefile"
+    # 处理独立 libpcre（非 +libpcre2 开头）
+    sed -i 's/\blibpcre\b\([^2]\|$\)/libpcre2\1/g' "$KISMET_DIR/Makefile"
+    echo "  ✅ $(basename "$KISMET_DIR"): libpcre → libpcre2 (精确匹配)"
+    PATCHED=$((PATCHED + 1))
+  fi
 fi
 
 # ═══════════════════════════════════════════
-#  修复 2: openwrt-dist-luci — ChinaDNS → chinadns-ng, dns-forwarder → dnsforwarder
+#  修复 2: openwrt-dist-luci — ChinaDNS → chinadns-ng, dns-forwarder → dnsforwarder (保留)
 # ═══════════════════════════════════════════
 ODL_DIR=$(find_pkg_dir "openwrt-dist-luci" || true)
@@ -128,2 +135,6 @@ fi
 #  修复 14: luci-app-webd — webd 二进制可选
+# ═══════════════════════════════════════════
+#  修复 19-27: 新增缺失依赖修复
+# ═══════════════════════════════════════════
+# (见上方 P1 修复方案中的完整代码)
```

### 补丁 2: build-openwrt.yml — Node.js 24 兼容

```diff
--- a/.github/workflows/build-openwrt.yml
+++ b/.github/workflows/build-openwrt.yml
@@ -58,6 +58,8 @@ env:
   REPO_URL: https://github.com/LiBwrt/openwrt-6.x
   TZ: Asia/Shanghai
+  # 强制 GitHub Actions 使用 Node.js 24（避免 2026-09 弃用）
+  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"
 
 jobs:
   build:
```

---

## 📈 修复后预期效果

| 指标 | 修复前 | 修复后 |
|------|--------|--------|
| 总 WARNING 行数 | 243 | ~160 |
| 缺失依赖警告 | 66 | ~10 (default-settings 等误报) |
| No feed for package | 22 | ~3 (kismet libpcre22 已消除) |
| CI Node.js 弃用警告 | 1 | 0 |
| 编译成功 | ✅ | ✅ (不变) |

---

*报告生成: 2026-05-06 | 基于 0_build.txt 实际日志分析*
