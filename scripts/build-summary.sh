#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  编译结果摘要 → GITHUB_STEP_SUMMARY
#  用法: build-summary.sh <work_dir>
# ═══════════════════════════════════════════
set -euo pipefail

WORK_DIR="${1:-.}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

cd "$WORK_DIR"

echo "### 📊 编译结果" >> "$SUMMARY"

# ── 错误/警告统计 ──
if [ -f build.log ]; then
  ERRORS=$(grep -ci "error" build.log 2>/dev/null || echo 0)
  WARNINGS=$(grep -ci "warning" build.log 2>/dev/null || echo 0)
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

FIRMWARE_FILES=$(find bin/targets/ -type f \( \
  -name "*.bin" -o -name "*.itb" -o -name "*.img" \
  -o -name "*.ubi" -o -name "*.tar" \) 2>/dev/null | head -30)

if [ -n "$FIRMWARE_FILES" ]; then
  echo "$FIRMWARE_FILES" | while read f; do
    SIZE=$(du -sh "$f" 2>/dev/null | cut -f1)
    SHA=$(sha256sum "$f" 2>/dev/null | cut -c1-16)
    echo "- \`${f}\` (${SIZE}) [\`${SHA}...\`]" >> "$SUMMARY"
  done
else
  echo "⚠️ 未找到固件文件" >> "$SUMMARY"
fi

# ── 终端输出 ──
echo "═══════════════════════════════════════"
echo "  编译结果"
echo "  错误: ${ERRORS:-0}"
echo "  警告: ${WARNINGS:-0}"
echo "  固件: $(echo "$FIRMWARE_FILES" | wc -l) 个文件"
echo "═══════════════════════════════════════"
