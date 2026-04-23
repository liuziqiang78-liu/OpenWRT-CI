#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  克隆源码 + 安装 Feeds
#  从 config/feeds.yml 读取外来源配置
#
#  用法: setup-source.sh <repo_url> <branch> <work_dir> [config_dir]
# ═══════════════════════════════════════════
set -euo pipefail

REPO_URL="${1:?用法: setup-source.sh <repo_url> <branch> <work_dir> [config_dir]}"
BRANCH="${2:?}"
WORK_DIR="${3:-openwrt}"
CONFIG_DIR="${4:-config}"

echo "📦 克隆源码: ${REPO_URL} @ ${BRANCH}"
git clone --depth 1 --single-branch -b "$BRANCH" "$REPO_URL" "$WORK_DIR"

cd "$WORK_DIR"

# ── 从 feeds.yml 读取外来源 ──
FEEDS_FILE="../${CONFIG_DIR}/feeds.yml"
if [ -f "$FEEDS_FILE" ]; then
  echo "📥 从 feeds.yml 加载外来源"

  # 解析 feeds.yml 中的第三方源 (排除 openwrt/luci/routing/telephony 官方源)
  while IFS= read -r line; do
    # 提取 url 和 name
    FEED_NAME=$(echo "$line" | grep -oP '^\s+- name:\s*\K\S+' || true)
    FEED_URL=$(echo "$line" | grep -oP 'url:\s*\K\S+' || true)
    FEED_BRANCH=$(echo "$line" | grep -oP 'branch:\s*\K\S+' || true)

    if [ -n "$FEED_URL" ] && [ -n "$FEED_NAME" ]; then
      # 跳过官方源
      case "$FEED_NAME" in
        openwrt|luci|routing|telephony) continue ;;
      esac
      echo "  → ${FEED_NAME}: ${FEED_URL} @ ${FEED_BRANCH:-main}"
      echo "src-git ${FEED_NAME} ${FEED_URL}" >> feeds.conf.default
    fi
  done < <(python3 -c "
import yaml, sys
with open('${FEEDS_FILE}') as f:
    data = yaml.safe_load(f)
for name, info in data.get('feeds', {}).items():
    if name not in ('openwrt','luci','routing','telephony'):
        print(f'- name: {name}')
        print(f'  url: {info[\"url\"]}')
        print(f'  branch: {info.get(\"branch\",\"main\")}')
" 2>/dev/null || true)
else
  echo "📥 feeds.yml 不存在，使用默认外来源"
  cat >> feeds.conf.default <<'EOF'
src-git kenzo https://github.com/kenzok8/openwrt-packages
src-git small https://github.com/kenzok8/small
EOF
fi

echo ""
echo "📥 当前 feeds 配置:"
cat feeds.conf.default
echo ""

echo "📥 更新 feeds"
./scripts/feeds update -a

echo "📥 安装 feeds"
./scripts/feeds install -a

echo "✅ 源码准备完成"
