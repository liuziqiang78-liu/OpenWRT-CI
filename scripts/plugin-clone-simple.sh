#!/bin/bash

# 简单的插件克隆脚本 - 使用本地仓库映射

REPO_MAP="$GITHUB_WORKSPACE/plugin-repos.json"

# 清理插件名称（移除可能的 luci-app- 前缀）
clean_plugin_name() {
    echo "$1" | sed -e 's/^luci-app-//' -e 's/^luci-//'
}

# 获取仓库地址
get_repo_url() {
    local plugin="$1"
    local clean_plugin=$(clean_plugin_name "$plugin")
    
    # 首先尝试直接匹配
    local repo=$(jq -r --arg pkg "$plugin" '.[$pkg]' "$REPO_MAP" 2>/dev/null)
    
    if [ -n "$repo" ] && [ "$repo" != "null" ]; then
        echo "$repo"
        return 0
    fi
    
    # 如果没有找到，尝试通用模式
    local generic_patterns=$(jq -r '.generic_patterns[]' "$REPO_MAP" 2>/dev/null)
    
    for pattern in $generic_patterns; do
        local repo_url=$(echo "$pattern" | sed "s/{plugin}/$clean_plugin/g")
        # 简单检查 URL 格式
        if [[ "$repo_url" =~ ^https://github\.com/ ]]; then
            echo "$repo_url"
            return 0
        fi
    done
    
    echo ""
}

# 克隆插件
clone_plugin() {
    local plugin="$1"
    local clean_plugin=$(clean_plugin_name "$plugin")
    
    echo "安装插件：$plugin"
    echo "清理后插件名称：$clean_plugin"
    
    # 获取仓库地址
    local repo_url=$(get_repo_url "$plugin")
    
    if [ -z "$repo_url" ]; then
        echo "⚠️  无法找到插件 $plugin 的仓库地址"
        return 1
    fi
    
    echo "仓库地址：$repo_url"
    
    # 克隆仓库
    if git clone --depth=1 "$repo_url" 2>/dev/null; then
        echo "✅ 克隆成功: $plugin"
        return 0
    else
        echo "❌ 克隆失败: $plugin"
        return 1
    fi
}

# 检查插件是否存在映射
check_plugin_mapped() {
    local plugin="$1"
    local repo_url=$(get_repo_url "$plugin")
    
    if [ -n "$repo_url" ]; then
        return 0
    else
        return 1
    fi
}

# 主函数
main() {
    local action="$1"
    local plugin="$2"
    
    case "$action" in
        "clone")
            clone_plugin "$plugin"
            ;;
        "get-repo")
            get_repo_url "$plugin"
            ;;
        "check")
            check_plugin_mapped "$plugin" && echo "已映射" || echo "未映射"
            ;;
        *)
            echo "用法: $0 {clone|get-repo|check} [插件名]"
            exit 1
            ;;
    esac
}

# 如果直接调用，执行主函数
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    main "$@"
fi