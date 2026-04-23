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
  PARALLEL=$(($(nproc) + 1))
fi

echo "═══════════════════════════════════════"
echo "  编译流水线 (并行: ${PARALLEL})"
echo "═══════════════════════════════════════"

# ── Step 1: 下载源码包 ──
echo "📥 下载源码包..."
make download -j$(nproc) || {
  echo "⚠️ 并行下载失败，切换单线程重试..."
  make download -j1 V=s
}

# ── Step 2: 编译工具链 ──
echo "🔧 编译工具链..."
make tools/install -j$(nproc)
make toolchain/install -j$(nproc)

# ── Step 3: 编译固件 ──
echo "🏗️ 编译固件 (jobs=${PARALLEL})..."
make -j${PARALLEL} 2>&1 | tee build.log

echo "✅ 编译完成"
