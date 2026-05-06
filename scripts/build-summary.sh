#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  编译结果摘要 → GITHUB_STEP_SUMMARY
#  用法: build-summary.sh <work_dir>
# ═══════════════════════════════════════════
set -euo pipefail

WORK_DIR="${1:-.}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

# ── 公共函数：查找固件文件（供 build-summary.sh 和 post-build-check.sh 共用） ──
find_firmware_files() {
  find bin/targets/ -type f \( \
    -name "*.bin" -o -name "*.itb" -o -name "*.img" \
    -o -name "*.ubi" -o -name "*.tar" \) 2>/dev/null
}

cd "$WORK_DIR"

echo "### 📊 编译结果" >> "$SUMMARY"

# ── 错误/警告统计 ──
if [ -f build.log ]; then
  ERRORS=$(grep -cP "(: ?fatal error:|^make.*\*\*\*.*[Ee]rror|recipe for target.*failed)" build.log 2>/dev/null || true)
  ERRORS="${ERRORS:-0}"; ERRORS="${ERRORS//[^0-9]/}"; ERRORS="${ERRORS:-0}"
  WARNINGS=$(grep -cP "(^[^/]*:\d+: warning:|^.*WARNING:)" build.log 2>/dev/null || true)
  WARNINGS="${WARNINGS:-0}"; WARNINGS="${WARNINGS//[^0-9]/}"; WARNINGS="${WARNINGS:-0}"
  BUILD_TIME="unknown"
  if [ -f .build_start_time ]; then
    START=$(cat .build_start_time)
    NOW=$(date +%s)
    ELAPSED=$(( NOW - START ))
    BUILD_TIME="$(( ELAPSED / 60 ))m $(( ELAPSED % 60 ))s"
  fi

  cat >> "$SUMMARY" <<EOF
| 指标 | 值 |
|:---|:---|
| 错误数 | ${ERRORS} |
| 警告数 | ${WARNINGS} |
| 编译耗时 | ${BUILD_TIME} |
EOF
else
  echo "⚠️ build.log 不存在" >> "$SUMMARY"
fi

echo "" >> "$SUMMARY"

# ── 固件文件列表 ──
echo "### 📦 固件文件" >> "$SUMMARY"

FIRMWARE_FILES=$(find_firmware_files | head -30)

if [ -n "$FIRMWARE_FILES" ]; then
  echo "$FIRMWARE_FILES" | while read f; do
    SIZE=$(du -sh "$f" 2>/dev/null | cut -f1)
    SHA=$(sha256sum "$f" 2>/dev/null | cut -c1-16)
    echo "- \`${f}\` (${SIZE}) [\`${SHA}...\`]" >> "$SUMMARY"
  done
else
  echo "⚠️ 未找到固件文件" >> "$SUMMARY"
fi

# ── 警告分类报告 ──
echo ""
echo "### ⚠️ 警告分类" >> "$SUMMARY"

MISSING_DEP=$(grep -cP "has a dependency on.*which does not exist" build.log 2>/dev/null || echo 0)
COMPILER_WARN=$(grep -cP ": warning:.*\[-W" build.log 2>/dev/null || echo 0)
DOWNLOAD_FAIL=$(grep -cP "Download failed" build.log 2>/dev/null || echo 0)
AUTORECONF_ERR=$(grep -cP "autoreconf: error" build.log 2>/dev/null || echo 0)
OPENSSL_DEPR=$(grep -cP "is deprecated: Since OpenSSL" build.log 2>/dev/null || echo 0)

cat >> "$SUMMARY" <<EOF
| 类别 | 数量 | 说明 |
|:---|:---|:---|
| 缺失依赖 | ${MISSING_DEP} | fix-dependencies.sh 可修补 |
| 编译器警告 | ${COMPILER_WARN} | 上游代码，需等上游修复 |
| OpenSSL 废弃 API | ${OPENSSL_DEPR} | DES/MD4 已废弃，上游需迁移 |
| 下载失败 | ${DOWNLOAD_FAIL} | 已自动回退 git clone |
| autoreconf 错误 | ${AUTORECONF_ERR} | Go bootstrap，不影响最终构建 |
EOF

# ── 终端输出 ──
# 使用 find_firmware_files 统计固件数量（修复空列表时 wc -l 输出 1 的 bug）
FIRMWARE_COUNT=$(find_firmware_files | wc -l)
# find 的输出通过管道到 wc，空输入时 wc -l 正确返回 0
# 但更保险的做法：如果 find 无输出，强制为 0
FIRMWARE_COUNT="${FIRMWARE_COUNT:-0}"

echo "═══════════════════════════════════════"
echo "  编译结果"
echo "  错误: ${ERRORS:-0}"
echo "  警告: ${WARNINGS:-0}"
echo "    ├─ 缺失依赖: ${MISSING_DEP}"
echo "    ├─ 编译器:    ${COMPILER_WARN}"
echo "    ├─ OpenSSL:   ${OPENSSL_DEPR}"
echo "    ├─ 下载失败:  ${DOWNLOAD_FAIL}"
echo "    └─ autoreconf: ${AUTORECONF_ERR}"
echo "  固件: ${FIRMWARE_COUNT} 个文件"
echo "═══════════════════════════════════════"
