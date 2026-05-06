#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  编译流水线: 下载 → 工具链 → 固件
#  用法: build.sh <work_dir> [parallel_jobs]
# ═══════════════════════════════════════════
set -euo pipefail

WORK_DIR="${1:-.}"
PARALLEL="${2:-0}"

cd "$WORK_DIR"

if [ "$PARALLEL" -le 0 ]; then
  PARALLEL=$(($(nproc 2>/dev/null || echo 2) + 1))
fi

echo "═══════════════════════════════════════"
echo "  编译流水线 (并行: ${PARALLEL})"
echo "═══════════════════════════════════════"

# ── 带重试的构建步骤 ──
build_step() {
  local desc="$1"
  shift
  local max_retries=2
  local attempt=0
  while [ "$attempt" -le "$max_retries" ]; do
    if [ "$attempt" -gt 0 ]; then
      echo "⚠️ ${desc} 失败，第 ${attempt} 次重试..."
      sleep 5
    fi
    if "$@"; then
      return 0
    fi
    attempt=$((attempt + 1))
  done
  echo "❌ ${desc} 失败 (已重试 ${max_retries} 次)"
  return 1
}

# ── 清理旧日志 ──
rm -f build.log

# ── Step 1: 下载源码包 ──
echo "📥 下载源码包..."
build_step "下载源码包" make download -j"${PARALLEL}" || {
  echo "⚠️ 并行下载失败，切换单线程重试..."
  build_step "下载源码包(单线程)" make download -j1 V=s
}

# ── Step 2: 编译工具链 ──
echo "🔧 编译工具链..."
build_step "编译工具" make tools/install -j"${PARALLEL}"
build_step "编译工具链" make toolchain/install -j"${PARALLEL}"

# ── Step 3: 编译固件 ──
echo "🏗️ 编译固件 (jobs=${PARALLEL})..."
make -j"${PARALLEL}" V=s 2>&1 | tee build.log

echo "✅ 编译完成"
