# OpenWRT-CI 构建脚本代码质量分析报告

> 分析时间: 2026-05-06
> 分析范围: `scripts/` 目录下 10 个构建脚本

---

## 目录

1. [严重问题](#严重问题)
2. [中等问题](#中等问题)
3. [建议改进](#建议改进)
4. [跨脚本接口一致性](#跨脚本接口一致性)
5. [汇总统计](#汇总统计)

---

## 严重问题

### 🔴 S1: fix-dependencies.sh — kismet libpcre 修复存在复合替换 Bug

**文件**: `fix-dependencies.sh` 第 47-48 行
**级别**: 严重

**问题描述**: 两次连续的 `fix_dep` 调用会产生级联破坏。假设 kismet Makefile 中原始依赖为 `+libpcre`（PCRE1）：

1. 第一次调用 `fix_dep ... "+libpcre" "+libpcre2"` → sed `s/+libpcre/+libpcre2/g` → `+libpcre` 变为 `+libpcre2` ✓
2. 第二次调用 `fix_dep ... "libpcre" "libpcre2"` → sed `s/libpcre/libpcre2/g` → 匹配到刚写入的 `+libpcre2` 中的 `libpcre` → 变为 `+libpcre22` ✗

更严重的是，如果原始依赖恰好是 `+libpcre22`（OpenWrt PCRE2 的实际包名），则：
- `s/+libpcre/+libpcre2/g` → `+libpcre222`（多了一个 2）
- `s/libpcre/libpcre2/g` → `+libpcre2222`（灾难性）

根因：`sed` 的 `s/old/new/g` 做的是子串匹配，`libpcre` 是 `libpcre2`、`libpcre22` 的前缀，替换后剩余字符被拼接，导致无限膨胀。

**修复代码**:

```bash
# ── 修复 1: kismet — libpcre → libpcre2 ──
KISMET_DIR=$(find_pkg_dir "kismet" || true)
if [ -n "$KISMET_DIR" ]; then
  # 使用 perl 负向前瞻，只匹配 libpcre 后面不跟 2 的情况
  # 这样 libpcre → libpcre2，但 libpcre2 和 libpcre22 不受影响
  if [ -f "$KISMET_DIR/Makefile" ] && grep -q 'libpcre' "$KISMET_DIR/Makefile" 2>/dev/null; then
    perl -i -pe 's/\+libpcre(?!2)/+libpcre2/g; s/(?<!\+)libpcre(?!2)/libpcre2/g' "$KISMET_DIR/Makefile"
    echo "  ✅ $(basename "$(dirname "$KISMET_DIR/Makefile")"): libpcre → libpcre2 (精确匹配)"
    PATCHED=$((PATCHED + 1))
  fi
fi
```

如果没有 `perl`，可以用多次 sed 并加保护：

```bash
if [ -n "$KISMET_DIR" ]; then
  MKFILE="$KISMET_DIR/Makefile"
  if [ -f "$MKFILE" ] && grep -q 'libpcre' "$MKFILE" 2>/dev/null; then
    # 先把 libpcre2 临时标记为 __LIBPCRE2__，避免被后续替换误伤
    sed -i 's/+libpcre2/+__LIBPCRE2__/g; s/libpcre2/__LIBPCRE2__/g' "$MKFILE"
    # 再替换 libpcre → libpcre2
    sed -i 's/+libpcre/+libpcre2/g; s/libpcre/libpcre2/g' "$MKFILE"
    # 还原标记
    sed -i 's/+__LIBPCRE2__/+libpcre2/g; s/__LIBPCRE2__/libpcre2/g' "$MKFILE"
    echo "  ✅ $(basename "$(dirname "$MKFILE")"): libpcre → libpcre2"
    PATCHED=$((PATCHED + 1))
  fi
fi
```

---

### 🔴 S2: fix-dependencies.sh — fix_dep 的 sed 模式无边界保护，全局替换风险

**文件**: `fix-dependencies.sh` `fix_dep()` 函数
**级别**: 严重

**问题描述**: `fix_dep` 使用 `sed -i "s/$old/$new/g"`，其中 `$old` 和 `$new` 直接插入 sed 表达式，存在两个风险：

1. **无单词边界**: `old="boost-system"` 会匹配 `boost-system-dev`、`boost-system-libs` 等所有包含该子串的依赖。
2. **sed 特殊字符未转义**: 如果 `$old` 或 `$new` 包含 `/`、`&`、`\` 等 sed 元字符，会导致替换失败或产生意外结果。例如 `fix_dep ... "foo/bar" "baz"` 会因 `/` 分隔符冲突而报错。

**修复代码**:

```bash
fix_dep() {
  local file="$1" old="$2" new="$3"
  if [ -f "$file" ]; then
    if grep -qF "$old" "$file" 2>/dev/null; then
      # 转义 sed 特殊字符
      local old_escaped new_escaped
      old_escaped=$(printf '%s\n' "$old" | sed 's/[&/\]/\\&/g')
      new_escaped=$(printf '%s\n' "$new" | sed 's/[&/\]/\\&/g')
      sed -i "s/${old_escaped}/${new_escaped}/g" "$file"
      echo "  ✅ $(basename "$(dirname "$file")"): $old → $new"
      PATCHED=$((PATCHED + 1))
    fi
  fi
}
```

---

### 🔴 S3: build.sh — tools/toolchain 编译失败无重试，直接中断流水线

**文件**: `build.sh` 第 24-25 行
**级别**: 严重

**问题描述**: `make download` 有失败重试逻辑（并行失败后切换单线程），但 `make tools/install` 和 `make toolchain/install` 没有任何容错。在 CI 环境中，偶发的网络超时、磁盘 I/O 错误会导致整个构建直接失败，而这些问题通常重试一次就能解决。

**修复代码**:

```bash
# ── Step 2: 编译工具链 (带重试) ──
echo "🔧 编译工具链..."
build_step() {
  local desc="$1"; shift
  local retries=2
  for ((i=1; i<=retries; i++)); do
    echo "  → ${desc} (尝试 ${i}/${retries})..."
    if "$@"; then
      return 0
    fi
    echo "  ⚠️ ${desc} 失败，等待 10s 后重试..."
    sleep 10
  done
  echo "  ❌ ${desc} 在 ${retries} 次尝试后仍然失败"
  return 1
}

build_step "编译工具链" make tools/install -j"$(nproc)"
build_step "编译工具链" make toolchain/install -j"$(nproc)"
```

---

## 中等问题

### 🟡 M1: setup-source.sh — 临时文件无 trap 清理

**文件**: `setup-source.sh` 第 30 行
**级别**: 中等

**问题描述**: `FEED_LIST=$(mktemp)` 创建了临时文件，虽然脚本末尾有 `rm -f "$FEED_LIST"`，但如果脚本在中间步骤因 `set -e` 退出（如 `git clone` 失败、`feeds update` 失败），临时文件不会被清理。在频繁重试的 CI 环境中会积累大量 `/tmp/tmp.*` 文件。

**修复代码**:

```bash
set -euo pipefail

# 在脚本开头添加 trap
cleanup() {
  [ -n "${FEED_LIST:-}" ] && rm -f "$FEED_LIST"
}
trap cleanup EXIT

# ... 后续代码不变 ...
```

---

### 🟡 M2: build.sh — make -j 参数不一致

**文件**: `build.sh`
**级别**: 中等

**问题描述**: 三个 make 阶段使用了不同的并行策略：
- `make download -j$(nproc)` — 使用 nproc
- `make tools/install -j$(nproc)` — 使用 nproc
- `make toolchain/install -j$(nproc)` — 使用 nproc
- `make -j${PARALLEL} V=s` — 使用 PARALLEL (nproc+1)

`PARALLEL` 参数仅用于最终固件编译，但下载和工具链阶段忽略了用户传入的并行数。在 CI 资源受限时（如 GitHub Actions 的 2 核机器），用户可能希望通过参数限制并行数以避免 OOM。

**修复代码**:

```bash
# 统一使用 PARALLEL 作为所有 make 的并行数
echo "📥 下载源码包..."
make download -j"${PARALLEL}" || {
  echo "⚠️ 并行下载失败，切换单线程重试..."
  make download -j1 V=s
}

echo "🔧 编译工具链..."
make tools/install -j"${PARALLEL}"
make toolchain/install -j"${PARALLEL}"

echo "🏗️ 编译固件 (jobs=${PARALLEL})..."
make -j"${PARALLEL}" V=s 2>&1 | tee build.log
```

---

### 🟡 M3: generate-manifest.sh — JSON 手工拼接，存在注入和格式风险

**文件**: `generate-manifest.sh` 第 40-55 行
**级别**: 中等

**问题描述**: 使用字符串拼接构造 JSON，存在以下风险：
1. `SAFE_PATH` 的 sed 转义不完整 — 只处理了 `\` 和 `"`，未处理换行符、制表符等控制字符。
2. `TARGET`、`SUBTARGET` 等变量如果为空或包含特殊字符，会导致 JSON 格式错误。
3. 每个 firmware entry 之间用 `echo ','` 分隔的方式在大量文件时效率低。

**修复代码**:

```bash
# 使用 jq 构造 JSON（如果可用），否则加强转义
if command -v jq &>/dev/null; then
  # 收集固件信息到数组
  FIRMWARE_JSON="[]"
  while IFS= read -r f; do
    SIZE=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)
    SHA256=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
    FIRMWARE_JSON=$(echo "$FIRMWARE_JSON" | jq --arg p "$f" --argjson s "$SIZE" --arg h "$SHA256" \
      '. + [{"path":$p,"size":$s,"sha256":$h}]')
  done < <(find bin/targets/ -type f \( -name "*.bin" -o -name "*.itb" -o -name "*.img" \
    -o -name "*.ubi" -o -name "*.tar" \) 2>/dev/null | sort)

  jq -n --argjson fw "$FIRMWARE_JSON" \
    --arg t "${TARGET:-unknown}" --arg st "${SUBTARGET:-unknown}" \
    --arg d "${DEVICE:-all}" --arg f "${FIREWALL}" \
    --arg b "${BRANCH}" --arg c "${COMMIT}" --arg bd "${BUILD_DATE}" \
    '{"firmware":$fw,"meta":{"target":$t,"subtarget":$st,"device":$d,"firewall":$f,"branch":$b,"commit":$c,"build_date":$bd}}' \
    > "$OUTPUT"
else
  # fallback: 加强转义
  safe_json_string() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' '
  fi
  # ... 使用 safe_json_string 处理所有变量 ...
fi
```

---

### 🟡 M4: post-build-check.sh / build-summary.sh — 固件查找模式重复

**文件**: `post-build-check.sh` 第 20-21 行, `build-summary.sh` 第 40-42 行
**级别**: 中等

**问题描述**: 固件文件的 `find` 命令（匹配 `*.bin *.itb *.img *.ubi *.tar`）在两个脚本中完全重复。如果将来需要添加新的固件格式（如 `*.squashfs`），需要同时修改两处，容易遗漏。

**修复代码**:

提取为共享常量或函数：

```bash
# 在 scripts/lib/common.sh 中定义
find_firmware_files() {
  find "${1:-bin/targets/}" -type f \( \
    -name "*.bin" -o -name "*.itb" -o -name "*.img" \
    -o -name "*.ubi" -o -name "*.tar" \) 2>/dev/null
}
```

---

### 🟡 M5: build-summary.sh — 空固件列表时 wc -l 计数错误

**文件**: `build-summary.sh` 第 62 行
**级别**: 中等

**问题描述**: 当 `FIRMWARE_FILES` 为空时，`echo "$FIRMWARE_FILES" | wc -l` 输出 `1`（因为 `echo ""` 产生一个空行），导致终端输出显示 `固件: 1 个文件` 而实际为 0。

**修复代码**:

```bash
# 替换最后的固件计数
FIRMWARE_COUNT=0
if [ -n "$FIRMWARE_FILES" ]; then
  FIRMWARE_COUNT=$(echo "$FIRMWARE_FILES" | wc -l)
fi
echo "  固件: ${FIRMWARE_COUNT} 个文件"
```

---

### 🟡 M6: apply-system-config.sh — Python crypt 模块已废弃

**文件**: `apply-system-config.sh` 第 33 行
**级别**: 中等

**问题描述**: `crypt` 模块在 Python 3.11 中被标记为 [deprecated](https://docs.python.org/3/library/crypt.html)，在 Python 3.13 中已被移除。虽然有 `openssl passwd -6` 的 fallback，但如果 openssl 版本不支持 `-6`（需要 OpenSSL 1.1.1+），密码设置会静默失败，只输出 `::warning::`。

**修复代码**:

```bash
# 优先使用 openssl（更可靠），python crypt 作为 fallback
HASHED_PW=$(openssl passwd -6 "$ROOT_PW" 2>/dev/null || \
             python3 -c "import crypt,sys; print(crypt.crypt(sys.argv[1], crypt.mksalt(crypt.METHOD_SHA512)))" "$ROOT_PW" 2>/dev/null || \
             mkpasswd -m sha-512 "$ROOT_PW" 2>/dev/null || echo "")
if [ -n "$HASHED_PW" ]; then
  printf "root:%s:19797:0:99999:7:::\n" "$HASHED_PW" > files/etc/shadow
  chmod 600 files/etc/shadow
  echo "  ✅ 密码已设置"
else
  echo "::error::密码加密失败 (openssl/python3/mkpasswd 均不可用)"
  exit 1
fi
```

---

### 🟡 M7: generate-config.sh — 平台配置 glob 展开在无匹配时行为不可预测

**文件**: `generate-config.sh` 第 57-63 行
**级别**: 中等

**问题描述**: 

```bash
for candidate in \
  "${CONFIG_DIR}/platforms/*/${TARGET}/_platform.yml" \
  "${CONFIG_DIR}/platforms/${TARGET}.yml"; do
```

当 glob 模式 `${CONFIG_DIR}/platforms/*/${TARGET}/_platform.yml` 无匹配时，bash 默认将 glob 作为字面字符串保留（除非设置了 `shopt -s nullglob`）。此时 `candidate` 会是包含 `*` 的字面路径，`[ -f "$candidate" ]` 正确返回 false，逻辑上不会出错。但如果目录名中恰好包含 `*` 字符（极端情况），可能产生误匹配。

**修复代码**:

```bash
# 在脚本开头设置 nullglob，或使用更安全的查找方式
PLATFORM_FILE=""
while IFS= read -r -d '' candidate; do
  PLATFORM_FILE="$candidate"
  break
done < <(find "${CONFIG_DIR}/platforms" -path "*/${TARGET}/_platform.yml" -print0 2>/dev/null)

if [ -z "$PLATFORM_FILE" ] && [ -f "${CONFIG_DIR}/platforms/${TARGET}.yml" ]; then
  PLATFORM_FILE="${CONFIG_DIR}/platforms/${TARGET}.yml"
fi
```

---

### 🟡 M8: validate-config.sh — ACTUAL_FW 变量在特定路径下可能未定义

**文件**: `validate-config.sh` 第 52-64 行
**级别**: 中等

**问题描述**: `ACTUAL_FW` 变量在 `if/elif/else` 分支中赋值，但如果 `set -u` 生效且 bash 版本的行为有差异，理论上可能在后续使用时报 "unbound variable"。虽然当前代码的 else 分支确保了赋值，但结构上不够防御性。

**修复代码**:

```bash
# 在使用前初始化默认值
ACTUAL_FW="unknown"
FW3=$(grep -c 'CONFIG_PACKAGE_firewall=y' "$CONFIG_FILE" || true)
FW4=$(grep -c 'CONFIG_PACKAGE_firewall4=y' "$CONFIG_FILE" || true)
if [ "$FW3" -gt 0 ] && [ "$FW4" -gt 0 ]; then
  error "防火墙冲突: firewall3 + firewall4 同时启用"
elif [ "$FW3" -gt 0 ]; then
  ACTUAL_FW="iptables"
elif [ "$FW4" -gt 0 ]; then
  ACTUAL_FW="nftables"
else
  warn "未检测到防火墙配置"
fi
```

---

## 建议改进

### 🟢 A1: generate-config.sh — yaml_get / yaml_get_list 是脆弱的 YAML 解析器

**文件**: `generate-config.sh` 第 47-75 行
**级别**: 建议

**问题描述**: 自实现的 YAML 解析函数基于 `grep -oP` 和 `awk`，只能处理非常简单的扁平或一层嵌套结构。如果 YAML 文件包含多行字符串、流式语法（`{}`、`[]`）、注释中的冒号、或缩进不一致，解析会失败或产生错误结果。

**建议**: 如果 CI 环境有 `yq`（Go 版本），优先使用：

```bash
yaml_get() {
  local file="$1" key="$2"
  if command -v yq &>/dev/null; then
    yq eval ".${key}" "$file" 2>/dev/null
  else
    grep -oP "^${key}:\s*\K.*" "$file" 2>/dev/null | head -1 | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/"
  fi
}
```

---

### 🟢 A2: setup-source.sh — bash fallback YAML 解析器过于脆弱

**文件**: `setup-source.sh` 第 36-50 行
**级别**: 建议

**问题描述**: 纯 bash 的 feeds.yml 解析器使用 `grep -oP` 提取 YAML 键值对，对缩进、格式高度敏感。如果 feeds.yml 的格式稍有变化（如缩进改为 4 空格、key 前后有额外空格），解析会静默失败，输出空列表。

**建议**: 添加解析结果校验：

```bash
# 解析后检查结果
if [ ! -s "$FEED_LIST" ]; then
  echo "⚠️ 未能从 feeds.yml 解析到任何外来源，检查文件格式"
  # 不要 fallback 到硬编码列表，而是报错让用户知道
  echo "错误: feeds.yml 存在但解析失败，请检查 YAML 格式"
  exit 1
fi
```

---

### 🟢 A3: build.sh — build.log 未做日志轮转

**文件**: `build.sh` 第 31 行
**级别**: 建议

**问题描述**: `tee build.log` 会追加到已有的 build.log。如果 CI 缓存了工作目录，上次构建的日志会与本次混合，导致 `build-summary.sh` 的错误统计不准确。

**修复代码**:

```bash
# 在构建开始前清理旧日志
rm -f build.log
echo "🏗️ 编译固件 (jobs=${PARALLEL})..."
make -j"${PARALLEL}" V=s 2>&1 | tee build.log
```

---

### 🟢 A4: generate-manifest.sh — .git 目录查找方式脆弱

**文件**: `generate-manifest.sh` 第 22-25 行
**级别**: 建议

**问题描述**: 

```bash
BRANCH=$(git -C "$(find . -name '.git' -maxdepth 2 -type d | head -1 | xargs dirname 2>/dev/null || echo .)" \
  rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
```

使用 `find` 查找 `.git` 目录再 `dirname`，如果工作目录下有多个 git 仓库（如 feeds 的子仓库），`head -1` 的结果不确定。

**修复代码**:

```bash
# 直接在工作目录执行 git 命令
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
```

---

### 🟢 A5: apply-system-config.sh — LAN IP 未做格式校验

**文件**: `apply-system-config.sh` 第 42 行
**级别**: 建议

**问题描述**: `--lan-ip` 参数直接写入 uci 脚本，未校验是否为合法 IPv4 地址。传入 `evil;rm -rf /` 会被写入 uci-defaults 脚本（虽然 `printf '%s'` 不会执行 shell 命令，但写入的脚本内容会是错误的）。

**修复代码**:

```bash
if [ -n "$LAN_IP" ] && [ "$LAN_IP" != "192.168.1.1" ]; then
  # 校验 IPv4 格式
  if ! echo "$LAN_IP" | grep -qP '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'; then
    echo "::error::无效的 LAN IP 地址: ${LAN_IP}"
    exit 1
  fi
  echo "🌐 设置 LAN IP: ${LAN_IP}"
  # ... 后续代码不变 ...
fi
```

---

### 🟢 A6: 各脚本缺少版本/来源标识

**文件**: 所有脚本
**级别**: 建议

**问题描述**: 没有脚本包含版本号或 commit hash，CI 日志中无法确认运行的是哪个版本的脚本。

**建议**: 在每个脚本的头部添加版本标识，或在 CI 中 `source scripts/lib/version.sh` 统一注入。

---

## 跨脚本接口一致性

| 脚本 | 接口风格 | 第一个参数 | 问题 |
|:---|:---|:---|:---|
| `build.sh` | 位置参数 | `<work_dir>` | ✅ 一致 |
| `setup-source.sh` | 位置参数 | `<repo_url>` | ⚠️ 首参不是 work_dir |
| `generate-config.sh` | `--` 选项 | `--target` | ✅ 一致 (与其他 -- 风格) |
| `fix-dependencies.sh` | 位置参数 | `<work_dir>` | ✅ 一致 |
| `post-build-check.sh` | 位置参数 | `<work_dir>` | ✅ 一致 |
| `build-summary.sh` | 位置参数 | `<work_dir>` | ✅ 一致 |
| `config-summary.sh` | 位置参数 | `<config_file>` | ⚠️ 首参是文件不是目录 |
| `generate-manifest.sh` | 位置参数 | `<work_dir>` | ✅ 一致 |
| `validate-config.sh` | `--` 选项 | `--config` | ✅ 一致 |
| `apply-system-config.sh` | `--` 选项 | `--work-dir` | ✅ 一致 |

**不一致问题**:

1. **接口风格混用**: `build.sh`、`setup-source.sh` 等使用位置参数，`generate-config.sh`、`validate-config.sh` 等使用 `--` 选项。建议统一为 `--` 选项风格，更易读且不易出错。

2. **setup-source.sh 首参不是 work_dir**: 大多数脚本首参是 `work_dir`，但 `setup-source.sh` 首参是 `repo_url`，调用者需要记住不同的参数顺序。

3. **config-summary.sh 首参是 config_file**: 与其他脚本的 `work_dir` 惯例不一致。

4. **工作目录约定不统一**: 有些脚本 `cd "$WORK_DIR"` 后在相对路径下操作（如 `build.sh`、`post-build-check.sh`），有些使用绝对路径（如 `generate-manifest.sh` 解析 OUTPUT 为绝对路径后再 cd）。

---

## 汇总统计

| 级别 | 数量 | 说明 |
|:---|:---|:---|
| 🔴 严重 | 3 | libpcre 复合替换 bug、sed 无边界保护、工具链编译无重试 |
| 🟡 中等 | 8 | 临时文件泄漏、并行策略不一致、JSON 拼接风险、固件模式重复、wc -l 计数错误、crypt 废弃、glob 展开、变量初始化 |
| 🟢 建议 | 6 | YAML 解析脆弱、日志轮转、git 查找方式、IP 校验、版本标识、接口风格统一 |

### 最高优先级修复建议

1. **立即修复**: S1 (libpcre 复合替换) — 会导致 kismet 编译必然失败
2. **尽快修复**: S2 (sed 边界保护) — 所有 fix_dep 调用都有潜在风险
3. **尽快修复**: M1 (临时文件 trap) — CI 环境 /tmp 空间有限
4. **下个迭代**: S3 (工具链重试)、M5 (wc -l)、M6 (crypt 废弃)
