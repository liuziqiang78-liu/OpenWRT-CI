#!/usr/bin/env bash
# ═══════════════════════════════════════════
#  克隆源码 + 安装 Feeds
#  从 config/feeds.yml 读取外来源配置
#
#  用法: setup-source.sh <repo_url> <branch> <work_dir> [config_dir]
# ═══════════════════════════════════════════
set -euo pipefail

# ── 清理临时文件 ──
FEED_LIST=""
cleanup() {
  [ -n "$FEED_LIST" ] && rm -f "$FEED_LIST"
}
trap cleanup EXIT

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

  # 生成 feeds 列表 (优先 python3+yaml，fallback 纯 bash)
  FEED_LIST=$(mktemp)
  if python3 -c "import yaml" 2>/dev/null; then
    python3 -c "
import yaml
with open('${FEEDS_FILE}') as f:
    data = yaml.safe_load(f)
for name, info in data.get('feeds', {}).items():
    if name not in ('openwrt','luci','routing','telephony'):
        print(f'{name}|{info[\"url\"]}|{info.get(\"branch\",\"main\")}')
" > "$FEED_LIST" 2>/dev/null || true
  fi

  # fallback: 纯 bash grep 解析 (无需 PyYAML)
  if [ ! -s "$FEED_LIST" ]; then
    _cur=""
    while IFS= read -r _line; do
      _n=$(echo "$_line" | grep -oP '^\s+- name:\s*\K\S+' || true)
      if [ -n "$_n" ]; then _cur="$_n"; continue; fi
      _u=$(echo "$_line" | grep -oP '\burl:\s*\K\S+' || true)
      if [ -n "$_u" ] && [ -n "$_cur" ]; then
        _b=$(echo "$_line" | grep -oP '\bbranch:\s*\K\S+' || true)
        echo "${_cur}|${_u}|${_b:-main}"
        _cur=""
      fi
    done < "$FEEDS_FILE" > "$FEED_LIST"
  fi

  # 解析并添加到 feeds.conf.default
  while IFS='|' read -r FEED_NAME FEED_URL FEED_BRANCH; do
    [ -z "$FEED_NAME" ] && continue
    case "$FEED_NAME" in
      openwrt|luci|routing|telephony) continue ;;
    esac
    echo "  → ${FEED_NAME}: ${FEED_URL} @ ${FEED_BRANCH}"
    echo "src-git ${FEED_NAME} ${FEED_URL} ${FEED_BRANCH}" >> feeds.conf.default
  done < "$FEED_LIST"
  rm -f "$FEED_LIST"
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

# ── 修复缺失依赖 ──
FIX_SCRIPT="$(cd .. && pwd)/scripts/fix-dependencies.sh"
if [ -x "$FIX_SCRIPT" ]; then
  bash "$FIX_SCRIPT" .
fi

echo "✅ 源码准备完成"
