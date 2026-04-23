#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  克隆源码 + 安装 Feeds
#  用法: setup-source.sh <repo_url> <branch> <work_dir>
# ═══════════════════════════════════════════
set -euo pipefail

REPO_URL="${1:?用法: setup-source.sh <repo_url> <branch> <work_dir>}"
BRANCH="${2:?}"
WORK_DIR="${3:-openwrt}"

echo "📦 克隆源码: ${REPO_URL} @ ${BRANCH}"
git clone --depth 1 --single-branch -b "$BRANCH" "$REPO_URL" "$WORK_DIR"

cd "$WORK_DIR"

echo "📥 添加外源 feeds"
cat >> feeds.conf.default <<'EOF'
src-git kenzo https://github.com/kenzok8/openwrt-packages
src-git small https://github.com/kenzok8/small
EOF

echo "📥 更新 feeds"
./scripts/feeds update -a

echo "📥 安装 feeds"
./scripts/feeds install -a

echo "✅ 源码准备完成"
