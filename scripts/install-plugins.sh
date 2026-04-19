#!/bin/bash
# install-plugins.sh - 从 plugins/ 目录安装插件到 OpenWRT 源码
#
# 用法:
#   bash install-plugins.sh <plugin1> [plugin2] ...    # 安装指定插件
#   bash install-plugins.sh --category <category>      # 安装某分类全部
#   bash install-plugins.sh --all                      # 安装全部
#   bash install-plugins.sh --list                     # 列出所有插件
#
# 环境变量:
#   PLUGINS_DIR  - 插件目录路径 (默认: 脚本所在目录/../plugins)
#   WRT_DIR      - OpenWRT 源码目录 (默认: ./wrt)
#   REPO_MAP     - plugin-repos.json 路径 (兼容模式)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGINS_DIR="${PLUGINS_DIR:-$SCRIPT_DIR/../plugins}"
WRT_DIR="${WRT_DIR:-./wrt}"
REPO_MAP="${REPO_MAP:-$SCRIPT_DIR/../plugin-repos.json}"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}✅ $*${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
log_fail() { echo -e "${RED}❌ $*${NC}"; }

# 列出所有插件
list_plugins() {
    echo "📦 可用插件列表:"
    echo ""
    local current_cat=""
    for dir in "$PLUGINS_DIR"/*/; do
        [ -d "$dir" ] || continue
        local config="$dir/config.json"
        [ -f "$config" ] || continue
        
        local name=$(jq -r '.name' "$config")
        local pkg=$(jq -r '.package' "$config")
        local cat=$(jq -r '.category' "$config")
        local desc=$(jq -r '.description' "$config")
        
        if [ "$cat" != "$current_cat" ]; then
            current_cat="$cat"
            echo ""
            case "$cat" in
                proxy)   echo "🔐 科学上网:" ;;
                storage) echo "💾 存储管理:" ;;
                network) echo "🌐 网络工具:" ;;
                theme)   echo "🎨 主题:" ;;
                system)  echo "🔧 系统工具:" ;;
                *)       echo "📦 ${cat}:" ;;
            esac
        fi
        echo "  $name ($pkg) - $desc"
    done
    echo ""
}

# 安装单个插件
install_plugin() {
    local plugin="$1"
    local plugin_dir="$PLUGINS_DIR/$plugin"
    
    if [ ! -d "$plugin_dir" ] || [ ! -f "$plugin_dir/config.json" ]; then
        log_warn "插件目录不存在: $plugin (尝试通用克隆)"
        # 回退到通用模式
        install_plugin_generic "$plugin"
        return $?
    fi
    
    local repo=$(jq -r '.repository' "$plugin_dir/config.json")
    local name=$(jq -r '.name' "$plugin_dir/config.json")
    
    echo "=== 安装: $name ($plugin) ==="
    echo "  仓库: $repo"
    
    # 克隆仓库
    local target_dir="$WRT_DIR/package/$plugin"
    if [ -d "$target_dir" ]; then
        log_warn "已存在，跳过克隆"
    else
        if git clone --depth=1 "$repo" "$target_dir" 2>/dev/null; then
            log_ok "克隆成功"
        else
            log_fail "克隆失败: $plugin"
            return 1
        fi
    fi
    
    # 写入配置
    if [ -f "$plugin_dir/config.mk" ]; then
        cat "$plugin_dir/config.mk" >> "$WRT_DIR/.config"
        log_ok "配置已写入"
    fi
}

# 通用克隆模式 (兼容 plugin-repos.json)
install_plugin_generic() {
    local plugin="$1"
    local clean_name=$(echo "$plugin" | sed -e 's/^luci-app-//' -e 's/^luci-//')
    
    if [ ! -f "$REPO_MAP" ]; then
        log_fail "plugin-repos.json 不存在，无法通用克隆: $plugin"
        return 1
    fi
    
    # 尝试直接映射
    local repo=$(jq -r --arg pkg "$plugin" '.[$pkg]' "$REPO_MAP" 2>/dev/null)
    if [ -n "$repo" ] && [ "$repo" != "null" ]; then
        echo "  仓库: $repo (来自 plugin-repos.json)"
        if git clone --depth=1 "$repo" "$WRT_DIR/package/$plugin" 2>/dev/null; then
            echo "CONFIG_PACKAGE_${plugin}=y" >> "$WRT_DIR/.config"
            log_ok "通用克隆成功"
            return 0
        fi
    fi
    
    # 尝试通用模式
    local patterns=$(jq -r '.generic_patterns[]' "$REPO_MAP" 2>/dev/null)
    for pattern in $patterns; do
        local url=$(echo "$pattern" | sed "s/{plugin}/$clean_name/g")
        echo "  尝试: $url"
        if git clone --depth=1 "$url" "$WRT_DIR/package/$plugin" 2>/dev/null; then
            echo "CONFIG_PACKAGE_${plugin}=y" >> "$WRT_DIR/.config"
            log_ok "通用克隆成功"
            return 0
        fi
    done
    
    log_fail "无法克隆: $plugin"
    return 1
}

# 安装某分类全部
install_category() {
    local category="$1"
    local count=0
    
    for dir in "$PLUGINS_DIR"/*/; do
        [ -d "$dir" ] || continue
        local config="$dir/config.json"
        [ -f "$config" ] || continue
        
        local cat=$(jq -r '.category' "$config")
        local pkg=$(jq -r '.package' "$config")
        
        if [ "$cat" = "$category" ]; then
            install_plugin "$pkg" && count=$((count + 1))
            echo ""
        fi
    done
    
    echo "📊 分类 $category: 成功安装 $count 个插件"
}

# 安装全部
install_all() {
    local count=0
    for dir in "$PLUGINS_DIR"/*/; do
        [ -d "$dir" ] || continue
        local config="$dir/config.json"
        [ -f "$config" ] || continue
        
        local pkg=$(jq -r '.package' "$config")
        install_plugin "$pkg" && count=$((count + 1))
        echo ""
    done
    echo "📊 共安装 $count 个插件"
}

# 主逻辑
case "${1:-}" in
    --list|-l)
        list_plugins
        ;;
    --category|-c)
        [ -z "$2" ] && { echo "用法: $0 --category <proxy|storage|network|theme|system>"; exit 1; }
        install_category "$2"
        ;;
    --all|-a)
        install_all
        ;;
    --help|-h)
        echo "用法:"
        echo "  $0 <plugin1> [plugin2] ...    安装指定插件"
        echo "  $0 --category <category>      安装某分类全部"
        echo "  $0 --all                      安装全部插件"
        echo "  $0 --list                     列出所有插件"
        ;;
    "")
        echo "请指定插件名，或使用 --list 查看可用插件"
        exit 1
        ;;
    *)
        for plugin in "$@"; do
            install_plugin "$plugin"
            echo ""
        done
        ;;
esac
