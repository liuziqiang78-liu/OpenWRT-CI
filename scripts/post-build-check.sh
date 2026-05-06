#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  编译后健康检查
#  验证固件文件完整性、大小合理性
#  用法: post-build-check.sh <work_dir> [target] [subtarget]
# ═══════════════════════════════════════════
set -euo pipefail

WORK_DIR="${1:-.}"
TARGET="${2:-}"
SUBTARGET="${3:-}"

cd "$WORK_DIR"

ERRORS=0

# ── 公共函数：查找固件文件（与 build-summary.sh 保持一致） ──
find_firmware_files() {
  find bin/targets/ -type f \( \
    -name "*.bin" -o -name "*.itb" -o -name "*.img" \
    -o -name "*.ubi" -o -name "*.tar" \) 2>/dev/null
}

echo "═══════════════════════════════════════"
echo "  编译后健康检查"
echo "═══════════════════════════════════════"

# ── 检查 1: 固件文件是否存在 ──
FIRMWARE_COUNT=$(find_firmware_files | wc -l)
FIRMWARE_COUNT="${FIRMWARE_COUNT:-0}"

if [ "$FIRMWARE_COUNT" -eq 0 ]; then
  echo "❌ 未找到任何固件文件"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ 找到 ${FIRMWARE_COUNT} 个固件文件"
fi

# ── 检查 2: 固件文件大小合理性 ──
while IFS= read -r f; do
  [ -z "$f" ] && continue
  SIZE=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)
  BASENAME=$(basename "$f")

  # 最小 1MB，最大 256MB
  if [ "$SIZE" -lt 1048576 ]; then
    echo "⚠️ ${BASENAME}: 文件过小 ($(numfmt --to=iec $SIZE))，可能编译不完整"
    ERRORS=$((ERRORS + 1))
  elif [ "$SIZE" -gt 268435456 ]; then
    echo "⚠️ ${BASENAME}: 文件过大 ($(numfmt --to=iec $SIZE))，可能包含多余内容"
  else
    echo "✅ ${BASENAME}: $(numfmt --to=iec $SIZE)"
  fi
done < <(find_firmware_files)

# ── 检查 3: build.log 无致命错误 ──
if [ -f build.log ]; then
  FATAL_ERRORS=$(grep -cP "(: ?fatal error:|^make.*\*\*\*.*[Ee]rror|recipe for target.*failed)" build.log 2>/dev/null || true)
  FATAL_ERRORS="${FATAL_ERRORS:-0}"
  FATAL_ERRORS="${FATAL_ERRORS//[^0-9]/}"
  FATAL_ERRORS="${FATAL_ERRORS:-0}"
  if [ "$FATAL_ERRORS" -gt 0 ]; then
    echo "❌ build.log 中有 ${FATAL_ERRORS} 个致命错误"
    grep -nP "(: ?fatal error:|^make.*\*\*\*.*[Ee]rror|recipe for target.*failed)" build.log | head -5
    ERRORS=$((ERRORS + 1))
  else
    echo "✅ build.log 无致命错误"
  fi
fi

# ── 检查 4: .config 与目标匹配 ──
if [ -n "$TARGET" ] && [ -f .config ]; then
  ACTUAL_TARGET=$(grep -oP 'CONFIG_TARGET_\K[a-z0-9]+(?==y)' .config | head -1)
  if [ "$ACTUAL_TARGET" != "$TARGET" ]; then
    echo "❌ Target 不匹配: 期望 ${TARGET}，实际 ${ACTUAL_TARGET}"
    ERRORS=$((ERRORS + 1))
  fi
fi

# ── 结果 ──
echo ""
echo "═══════════════════════════════════════"
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ 健康检查失败: ${ERRORS} 个问题"
  exit 1
else
  echo "✅ 健康检查通过"
  exit 0
fi
