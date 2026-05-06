# OpenWRT-CI 后端脚本 Bug 分析报告

> 分析时间: 2026-05-06  
> 分析范围: `scripts/` 目录下 10 个 Shell 脚本  
> 总计发现: **23 个问题** (3 高危 / 9 中危 / 11 低危)

---

## 目录

- [高危 (High)](#高危-high)
- [中危 (Medium)](#中危-medium)
- [低危 (Low)](#低危-low)
- [修复优先级建议](#修复优先级建议)

---

## 高危 (High)

### BUG-01: `build.sh:51` — `tee` 管道在 SIGPIPE 下导致误判构建失败

**严重程度**: 🔴 高危  
**维度**: 管道/重定向 bug

**问题描述**:  
`set -o pipefail` 下，`make 2>&1 | tee build.log` 管道的退出码取两者的最大值。如果 CI 环境中 tee 的 stdout 被下游关闭（SIGPIPE），tee 会以非零码退出，导致整个管道失败——即使 make 编译成功，脚本也会报错退出。

```bash
# 当前代码 (build.sh:51)
make -j"${PARALLEL}" V=s 2>&1 | tee build.log
```

**修复代码**:
```bash
# 使用 PIPESTATUS 检查 make 的退出码，忽略 tee 的失败
make -j"${PARALLEL}" V=s 2>&1 | tee build.log
MAKE_EXIT=${PIPESTATUS[0]}
if [ "$MAKE_EXIT" -ne 0 ]; then
  echo "❌ 编译失败 (exit code: ${MAKE_EXIT})"
  exit "$MAKE_EXIT"
fi
```

---

### BUG-02: `generate-manifest.sh:66` — Fallback JSON 拼接存在注入风险

**严重程度**: 🔴 高危  
**维度**: 安全 bug / Shell 语法 bug

**问题描述**:  
当 jq 不可用时，脚本使用 bash 变量直接拼接 JSON。虽然对路径做了 sed 转义，但 `${TARGET}`、`${SUBTARGET}`、`${BRANCH}`、`${COMMIT}` 等变量**未经任何转义**就直接嵌入 JSON 字符串。如果这些值包含双引号或反斜杠（理论上可由恶意 .config 注入），会产生非法 JSON。

```bash
# 当前代码 (generate-manifest.sh:69-70)
cat >> "$OUTPUT" <<EOF
],"meta":{"target":"${TARGET}","subtarget":"${SUBTARGET}","device":"${DEVICE:-all}","firewall":"${FIREWALL}","branch":"${BRANCH}","commit":"${COMMIT}","build_date":"${BUILD_DATE}"}}
EOF
```

**修复代码**:
```bash
# 对所有嵌入 JSON 的变量进行转义
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g'
}

cat >> "$OUTPUT" <<EOF
],"meta":{"target":"$(json_escape "$TARGET")","subtarget":"$(json_escape "$SUBTARGET")","device":"$(json_escape "${DEVICE:-all}")","firewall":"$(json_escape "$FIREWALL")","branch":"$(json_escape "$BRANCH")","commit":"$(json_escape "$COMMIT")","build_date":"$(json_escape "$BUILD_DATE")"}}
EOF
```

---

### BUG-03: `setup-source.sh:50-56` — Python 代码中路径注入

**严重程度**: 🔴 高危  
**维度**: 安全 bug

**问题描述**:  
`${FEEDS_FILE}` 直接嵌入 Python 字符串字面量。如果路径包含单引号（例如 `config'/feeds.yml`），会导致 Python 语法错误或代码注入。虽然 `CONFIG_DIR` 有默认值，但作为可接受参数的脚本，不应假设输入安全。

```python
# 当前代码 (setup-source.sh:52)
with open('${FEEDS_FILE}') as f:
```

**修复代码**:
```bash
# 方案 A: 通过环境变量传递路径，避免字符串拼接
FEEDS_FILE_PATH="$FEEDS_FILE" python3 -c "
import yaml, os, sys
feeds_file = os.environ['FEEDS_FILE_PATH']
with open(feeds_file) as f:
    data = yaml.safe_load(f)
for name, info in data.get('feeds', {}).items():
    if name not in ('openwrt','luci','routing','telephony'):
        print(f'{name}|{info[\"url\"]}|{info.get(\"branch\",\"main\")}')
" > "$FEED_LIST" 2>/dev/null || true
```

---

## 中危 (Medium)

### BUG-04: `fix-dependencies.sh:22` — perl 替换中 `${new}` 未转义

**严重程度**: 🟡 中危  
**维度**: 安全 bug / Shell 语法 bug

**问题描述**:  
`fix_dep()` 函数中，`${old}` 用 `\Q...\E` 做了字面量转义，但 `${new}` 直接嵌入替换部分。如果 `new` 包含 `/` 或 `\`，会破坏 perl 正则替换语法。

```bash
# 当前代码 (fix-dependencies.sh:22)
perl -pi -e "s/\Q${old}\E/${new}/g" "$file"
```

**修复代码**:
```bash
# 对 new 也做转义处理
fix_dep() {
  local file="$1" old="$2" new="$3"
  if [ -f "$file" ]; then
    if grep -qF "$old" "$file" 2>/dev/null; then
      # 使用 | 作为分隔符避免 / 冲突，并转义 new 中的特殊字符
      local escaped_new
      escaped_new=$(printf '%s' "$new" | sed 's/[&/\]/\\&/g')
      perl -pi -e "s/\Q${old}\E/${escaped_new}/g" "$file"
      echo "  ✅ $(basename "$(dirname "$file")"): $old → $new"
      PATCHED=$((PATCHED + 1))
    fi
  fi
}
```

---

### BUG-05: `config-summary.sh:15` — 空 ACTUAL_TARGET 导致错误的 grep 模式

**严重程度**: 🟡 中危  
**维度**: 逻辑 bug

**问题描述**:  
如果 `.config` 中没有 `CONFIG_TARGET_*=y`，`ACTUAL_TARGET` 为空字符串。下一行用它构造 grep 模式 `CONFIG_TARGET__\K...`，会匹配到非预期内容或返回空值，产生误导性的摘要输出。

```bash
# 当前代码 (config-summary.sh:14-15)
ACTUAL_TARGET=$(grep -oP 'CONFIG_TARGET_\K[a-z0-9]+(?==y)' "$CONFIG" | head -1)
ACTUAL_SUBTARGET=$(grep -oP "CONFIG_TARGET_${ACTUAL_TARGET}_\\K[a-z0-9]+(?==y)" "$CONFIG" | head -1)
```

**修复代码**:
```bash
ACTUAL_TARGET=$(grep -oP 'CONFIG_TARGET_\K[a-z0-9]+(?==y)' "$CONFIG" | head -1)
if [ -z "$ACTUAL_TARGET" ]; then
  echo "⚠️ 未找到 Target 配置"
  ACTUAL_TARGET="unknown"
  ACTUAL_SUBTARGET="unknown"
else
  ACTUAL_SUBTARGET=$(grep -oP "CONFIG_TARGET_${ACTUAL_TARGET}_\\K[a-z0-9]+(?==y)" "$CONFIG" | head -1)
fi
```

---

### BUG-06: `build.sh:11` — PARALLEL 参数未校验是否为数字

**严重程度**: 🟡 中危  
**维度**: 逻辑 bug / Shell 语法 bug

**问题描述**:  
如果第二个参数是非数字字符串（如 `build.sh /path abc`），`[ "$PARALLEL" -le 0 ]` 会报错退出，但错误信息不明确。

```bash
# 当前代码 (build.sh:9-13)
PARALLEL="${2:-0}"

if [ "$PARALLEL" -le 0 ]; then
```

**修复代码**:
```bash
PARALLEL="${2:-0}"

# 校验是否为有效数字
if ! [[ "$PARALLEL" =~ ^[0-9]+$ ]]; then
  echo "⚠️ 无效的并行数: ${PARALLEL}，使用默认值"
  PARALLEL=0
fi

if [ "$PARALLEL" -le 0 ]; then
  PARALLEL=$(($(nproc 2>/dev/null || echo 2) + 1))
fi
```

---

### BUG-07: `post-build-check.sh:52` — `numfmt` 调用中变量未加引号

**严重程度**: 🟡 中危  
**维度**: Shell 语法 bug

**问题描述**:  
`$SIZE` 未加引号传给 `numfmt`。虽然 SIZE 由 `stat` 产生应为纯数字，但如果 stat 失败且 `echo 0` 也异常，可能导致 word splitting。

```bash
# 当前代码 (post-build-check.sh:52)
echo "⚠️ ${BASENAME}: 文件过小 ($(numfmt --to=iec $SIZE))，可能编译不完整"
```

**修复代码**:
```bash
echo "⚠️ ${BASENAME}: 文件过小 ($(numfmt --to=iec "$SIZE"))，可能编译不完整"
```

---

### BUG-08: `build-summary.sh:46` — `read` 缺少 `-r` 标志

**严重程度**: 🟡 中危  
**维度**: Shell 语法 bug

**问题描述**:  
`while read f` 没有 `-r` 标志，会将反斜杠解释为转义字符。虽然固件文件名通常不含反斜杠，但这是 Shell 最佳实践违规。

```bash
# 当前代码 (build-summary.sh:46)
echo "$FIRMWARE_FILES" | while read f; do
```

**修复代码**:
```bash
echo "$FIRMWARE_FILES" | while IFS= read -r f; do
```

---

### BUG-09: `generate-manifest.sh:63` — `echo` 可能解释转义序列

**严重程度**: 🟡 中危  
**维度**: 平台兼容性 / Shell 语法 bug

**问题描述**:  
`echo "$f"` 在某些 shell（如 dash 或启用了 xpg_echo 的 bash）中会解释 `\n`、`\t` 等转义序列。应使用 `printf '%s'` 保证字面量输出。

```bash
# 当前代码 (generate-manifest.sh:63)
SAFE_PATH=$(echo "$f" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\n/\\n/g; s/\r/\\r/g')
```

**修复代码**:
```bash
SAFE_PATH=$(printf '%s' "$f" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')
# 注意: printf 不会产生 \n，所以不需要替换 \n/\r
```

---

### BUG-10: `generate-config.sh:213` — base64 解码失败时 .config 被部分写入

**严重程度**: 🟡 中危  
**维度**: 错误处理

**问题描述**:  
自定义配置通过 `base64 -d >> "$OUTPUT"` 直接追加到 .config。如果 base64 数据无效，`base64 -d` 会输出乱码或报错退出（`set -e` 触发），但之前已写入的内容不会回滚，留下损坏的 .config。

```bash
# 当前代码 (generate-config.sh:213)
echo "$CUSTOM_CONFIG" | base64 -d >> "$OUTPUT"
```

**修复代码**:
```bash
# 先解码到临时文件，验证成功后再追加
DECODED_CONFIG=$(echo "$CUSTOM_CONFIG" | base64 -d 2>/dev/null) || {
  echo "⚠️ 自定义配置 base64 解码失败，跳过"
  DECODED_CONFIG=""
}
if [ -n "$DECODED_CONFIG" ]; then
  printf '%s\n' "$DECODED_CONFIG" >> "$OUTPUT"
fi
```

---

### BUG-11: `generate-manifest.sh:44` — jq 循环中 O(N) 进程创建

**严重程度**: 🟡 中危  
**维度**: 并发/性能 bug

**问题描述**:  
每次循环迭代都执行 `echo "$FIRMWARE_JSON" | jq ...`，为每个固件文件创建一个新进程。如果固件文件很多（>50），JSON 生成会非常慢。

```bash
# 当前代码 (generate-manifest.sh:44)
FIRMWARE_JSON=$(echo "$FIRMWARE_JSON" | jq --arg p "$f" --argjson s "$SIZE" --arg h "$SHA256" \
  '. + [{"path":$p,"size":$s,"sha256":$h}]')
```

**修复代码**:
```bash
# 使用 jq 的 inputs + slurp 一次性处理
FIRMWARE_JSON=$(
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    SIZE=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)
    SHA256=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
    jq -nc --arg p "$f" --argjson s "$SIZE" --arg h "$SHA256" \
      '{"path":$p,"size":$s,"sha256":$h}'
  done <<< "$FIRMWARE_LIST" | jq -s '.'
)
```

---

### BUG-12: `setup-source.sh:76` — `grep -oP` 依赖 PCRE，非所有系统可用

**严重程度**: 🟡 中危  
**维度**: 平台兼容性

**问题描述**:  
Fallback YAML 解析器使用 `grep -oP`（Perl 正则），在没有 PCRE 支持的 grep（如某些 Alpine/BusyBox 环境）上会失败。

```bash
# 当前代码 (setup-source.sh:76)
_n=$(echo "$_line" | grep -oP '^\s+- name:\s*\K\S+' || true)
```

**修复代码**:
```bash
# 使用 sed 替代 grep -oP
_n=$(echo "$_line" | sed -n 's/^[[:space:]]*- name:[[:space:]]*//p' | head -1)
_u=$(echo "$_line" | sed -n 's/.*[[:space:]]url:[[:space:]]*//p' | head -1)
_b=$(echo "$_line" | sed -n 's/.*[[:space:]]branch:[[:space:]]*//p' | head -1)
```

---

### BUG-13: `fix-dependencies.sh:63,139` — `sed` 中 `\b` 是 GNU 扩展

**严重程度**: 🟡 中危  
**维度**: 平台兼容性

**问题描述**:  
`\b`（单词边界）是 GNU sed 扩展，在 BSD sed（macOS）上不可用。虽然 CI 通常在 Linux 上运行，但降低了脚本的可移植性。

```bash
# 当前代码 (fix-dependencies.sh:63)
sed -i 's/+libpcre\b/+libpcre2/g' "$KISMET_DIR/Makefile"
```

**修复代码**:
```bash
# 使用 perl 替代（已在脚本中使用 perl，保持一致）
perl -pi -e 's/\+libpcre\b/+libpcre2/g' "$KISMET_DIR/Makefile"
# 或使用字符类模拟单词边界
sed -i 's/+libpcre\([^a-zA-Z0-9_-]\)/+libpcre2\1/g; s/+libpcre$/+libpcre2/' "$KISMET_DIR/Makefile"
```

---

## 低危 (Low)

### BUG-14: `post-build-check.sh` / `build-summary.sh` — `find_firmware_files` 函数重复定义

**严重程度**: 🟢 低危  
**维度**: 代码质量 / 维护性

**问题描述**:  
`find_firmware_files()` 在 `post-build-check.sh` 和 `build-summary.sh` 中各定义了一次。如果需要修改查找逻辑，必须同步修改两处，容易遗漏。

**修复建议**:  
提取到 `scripts/common.sh` 中，两个脚本 `source` 引用。

```bash
# scripts/common.sh
find_firmware_files() {
  find bin/targets/ -type f \( \
    -name "*.bin" -o -name "*.itb" -o -name "*.img" \
    -o -name "*.ubi" -o -name "*.tar" \) 2>/dev/null
}
```

---

### BUG-15: `generate-config.sh:78-93` — `yaml_get_list` 基于缩进的解析非常脆弱

**严重程度**: 🟢 低危  
**维度**: 逻辑 bug

**问题描述**:  
awk 脚本通过精确匹配缩进层级（2 空格、4 空格）来解析 YAML。如果 YAML 文件使用 tab 缩进、3 空格缩进、或有注释行，解析会失败或返回错误结果。

**修复建议**:  
优先使用 yq（如果可用），或添加缩进检测逻辑：

```bash
yaml_get_list() {
  local file="$1" prefix="$2"
  # 优先使用 yq
  if command -v yq &>/dev/null; then
    yq eval ".${prefix}[]" "$file" 2>/dev/null
    return
  fi
  # fallback 到现有 awk 逻辑
  ...
}
```

---

### BUG-16: `generate-config.sh:126` — `$PROFILE` 未引用，glob 展开风险

**严重程度**: 🟢 低危  
**维度**: Shell 语法 bug

**问题描述**:  
`for dev in $PROFILE` 中 `$PROFILE` 未加引号，如果设备名包含 `*` 或 `?`，会被 shell glob 展开。

```bash
# 当前代码 (generate-config.sh:126)
for dev in $PROFILE; do
```

**修复代码**:
```bash
# 使用 read -ra 安全分割
read -ra PROFILE_DEVICES <<< "$PROFILE"
for dev in "${PROFILE_DEVICES[@]}"; do
```

---

### BUG-17: `generate-config.sh:179` — yaml_get_list 返回值的 word splitting + glob

**严重程度**: 🟢 低危  
**维度**: Shell 语法 bug

**问题描述**:  
`for pkg in $(yaml_get_list ...)` 中命令替换结果会被 word splitting 和 glob 展开。如果包名包含空格或通配符，行为异常。

```bash
# 当前代码 (generate-config.sh:179)
for pkg in $(yaml_get_list "$PLATFORM_FILE" "packages.default" 2>/dev/null); do
```

**修复代码**:
```bash
# 使用 mapfile 安全读取
mapfile -t PKG_LIST < <(yaml_get_list "$PLATFORM_FILE" "packages.default" 2>/dev/null)
for pkg in "${PKG_LIST[@]}"; do
  [ -z "$pkg" ] && continue
  echo "CONFIG_PACKAGE_${pkg}=y" >> "$OUTPUT"
done
```

---

### BUG-18: `generate-manifest.sh:31` — git 分支检测可能找到错误的 `.git` 目录

**严重程度**: 🟢 低危  
**维度**: 逻辑 bug

**问题描述**:  
`find . -name '.git' -maxdepth 2` 在 OpenWrt 工作目录中可能找到 feeds 子目录中的 `.git`，导致读取错误的分支信息。

```bash
# 当前代码 (generate-manifest.sh:31)
BRANCH=$(git -C "$(find . -name '.git' -maxdepth 2 -type d | head -1 | xargs dirname ...)" \
  rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
```

**修复代码**:
```bash
# 直接在当前目录（已 cd 到 WORK_DIR）执行 git
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
```

---

### BUG-19: `validate-config.sh:61-62` — `grep -c` 可能误匹配注释行

**严重程度**: 🟢 低危  
**维度**: 逻辑 bug

**问题描述**:  
`grep -c 'CONFIG_PACKAGE_firewall=y'` 会匹配 `.config` 中的注释行（如 `# CONFIG_PACKAGE_firewall=y was deprecated`），产生误报。

```bash
# 当前代码 (validate-config.sh:61)
FW3=$(grep -c 'CONFIG_PACKAGE_firewall=y' "$CONFIG_FILE" || true)
```

**修复代码**:
```bash
# 只匹配非注释行
FW3=$(grep -c '^CONFIG_PACKAGE_firewall=y' "$CONFIG_FILE" || true)
FW4=$(grep -c '^CONFIG_PACKAGE_firewall4=y' "$CONFIG_FILE" || true)
```

---

### BUG-20: `build.sh:10` — `cd` 失败无友好错误提示

**严重程度**: 🟢 低危  
**维度**: 错误处理

**问题描述**:  
如果 `WORK_DIR` 不存在，`cd "$WORK_DIR"` 在 `set -e` 下直接退出，但没有有意义的错误信息。

```bash
# 当前代码 (build.sh:10)
cd "$WORK_DIR"
```

**修复代码**:
```bash
cd "$WORK_DIR" || {
  echo "❌ 工作目录不存在: ${WORK_DIR}"
  exit 1
}
```

---

### BUG-21: `generate-config.sh` — .config 写入非原子操作

**严重程度**: 🟢 低危  
**维度**: 错误处理 / 资源泄漏

**问题描述**:  
脚本逐步将内容追加到 `$OUTPUT`（.config）。如果中途失败（如 `make defconfig` 失败），会留下不完整的 .config 文件，可能被后续步骤误用。

**修复建议**:  
写入临时文件，成功后原子重命名：

```bash
TEMP_CONFIG=$(mktemp)
trap 'rm -f "$TEMP_CONFIG"' EXIT

# 所有写入改为 >> "$TEMP_CONFIG"
...
make defconfig  # 注意: defconfig 读取 .config，需要先 rename
mv "$TEMP_CONFIG" "$OUTPUT"
```

> 注: 由于 `make defconfig` 需要读取 `.config`，完整修复需要调整写入流程。

---

### BUG-22: `setup-source.sh:86` — fallback 解析器不处理 YAML 锚点/别名

**严重程度**: 🟢 低危  
**维度**: 逻辑 bug

**问题描述**:  
纯 bash fallback 解析器使用 `grep -oP` 按行匹配 `name:`/`url:`/`branch:`。如果 feeds.yml 使用 YAML 锚点（`&anchor`）或别名（`*alias`），解析结果会错误。

**修复建议**:  
在 fallback 解析前检测并警告：

```bash
if grep -q '[&*]' "$FEEDS_FILE" 2>/dev/null; then
  echo "⚠️ feeds.yml 包含 YAML 锚点/别名，bash 解析器可能无法正确处理"
fi
```

---

### BUG-23: `build-summary.sh:46` — 管道中 while 循环变量修改丢失

**严重程度**: 🟢 低危  
**维度**: Shell 语法 bug

**问题描述**:  
`echo ... | while read` 创建子 shell，循环内的变量修改在循环外不可见。当前代码只写文件所以没问题，但如果将来需要在循环后使用计数器，会踩坑。

```bash
# 当前代码 (build-summary.sh:46)
echo "$FIRMWARE_FILES" | while read f; do
  ...
done
```

**修复代码**:
```bash
# 使用 process substitution 避免子 shell
while IFS= read -r f; do
  ...
done <<< "$FIRMWARE_FILES"
```

---

## 修复优先级建议

| 优先级 | Bug ID | 文件 | 修复难度 |
|:---|:---|:---|:---|
| **P0 — 立即修复** | BUG-01 | build.sh | 低 |
| **P0 — 立即修复** | BUG-02 | generate-manifest.sh | 低 |
| **P0 — 立即修复** | BUG-03 | setup-source.sh | 低 |
| **P1 — 尽快修复** | BUG-04 | fix-dependencies.sh | 低 |
| **P1 — 尽快修复** | BUG-05 | config-summary.sh | 低 |
| **P1 — 尽快修复** | BUG-06 | build.sh | 低 |
| **P1 — 尽快修复** | BUG-07 | post-build-check.sh | 极低 |
| **P1 — 尽快修复** | BUG-08 | build-summary.sh | 极低 |
| **P1 — 尽快修复** | BUG-09 | generate-manifest.sh | 低 |
| **P1 — 尽快修复** | BUG-10 | generate-config.sh | 低 |
| **P2 — 计划修复** | BUG-11 | generate-manifest.sh | 中 |
| **P2 — 计划修复** | BUG-12 | setup-source.sh | 中 |
| **P2 — 计划修复** | BUG-13 | fix-dependencies.sh | 低 |
| **P3 — 择机修复** | BUG-14 ~ BUG-23 | 各文件 | 低~中 |

---

## 总结

| 类别 | 高危 | 中危 | 低危 | 合计 |
|:---|:---|:---|:---|:---|
| Shell 语法 bug | 1 | 3 | 3 | 7 |
| 逻辑 bug | 0 | 1 | 3 | 4 |
| 管道/重定向 bug | 1 | 0 | 0 | 1 |
| 并发/性能 bug | 0 | 1 | 0 | 1 |
| 平台兼容性 | 0 | 2 | 0 | 2 |
| 安全 bug | 2 | 1 | 0 | 3 |
| 资源泄漏 | 0 | 0 | 1 | 1 |
| 错误处理 | 0 | 1 | 1 | 2 |
| 代码质量 | 0 | 0 | 2 | 2 |
| **合计** | **3** | **9** | **11** | **23** |

**最高风险区域**: `generate-manifest.sh`（JSON 安全性）、`build.sh`（管道可靠性）、`setup-source.sh`（代码注入）

**最需要重构的函数**: `fix_dep()`（perl 转义）、`yaml_get_list()`（YAML 解析可靠性）、`find_firmware_files()`（去重）
