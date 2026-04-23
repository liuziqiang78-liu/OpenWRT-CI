#!/system/bin/sh
# MiMo Tool: Memory System
# 用法: memory.sh <action> [args...]

MEMORY_DIR="/data/adb/mimo/memory"
MEMORY_INDEX="$MEMORY_DIR/index.json"
mkdir -p "$MEMORY_DIR"

ACTION="$1"
shift
ARGS="$*"

# 初始化索引
init_index() {
    if [ ! -f "$MEMORY_INDEX" ]; then
        echo '{"memories":{},"created":"'$(date -Iseconds)'"}' > "$MEMORY_INDEX"
    fi
}

# 保存记忆
save_memory() {
    local key="$1"
    local value="$2"
    local timestamp=$(date -Iseconds)
    local id=$(echo "$key" | md5sum | cut -c1-8)
    
    init_index
    
    # 保存内容
    cat > "$MEMORY_DIR/${id}.json" << EOF
{
    "id": "$id",
    "key": "$key",
    "value": "$value",
    "timestamp": "$timestamp",
    "tags": []
}
EOF
    
    # 更新索引
    local current=$(cat "$MEMORY_INDEX")
    echo "$current" | sed "s/}$/,\"$id\":{\"key\":\"$key\",\"ts\":\"$timestamp\"}}/" > "$MEMORY_INDEX"
    
    echo "✓ 记忆已保存: $key"
}

# 搜索记忆
search_memory() {
    local query="$1"
    echo "🧠 搜索记忆: $query"
    echo "---"
    
    init_index
    
    # 搜索所有记忆文件
    grep -rl "$query" "$MEMORY_DIR"/*.json 2>/dev/null | while read -r f; do
        local key=$(grep -o '"key":"[^"]*"' "$f" | sed 's/"key":"//;s/"$//')
        local value=$(grep -o '"value":"[^"]*"' "$f" | sed 's/"value":"//;s/"$//')
        local ts=$(grep -o '"timestamp":"[^"]*"' "$f" | sed 's/"timestamp":"//;s/"$//')
        echo "[$ts] $key: $value"
    done
}

# 列出记忆
list_memory() {
    echo "🧠 所有记忆:"
    echo "---"
    
    init_index
    
    for f in "$MEMORY_DIR"/*.json; do
        [ "$f" = "$MEMORY_INDEX" ] && continue
        [ ! -f "$f" ] && continue
        local key=$(grep -o '"key":"[^"]*"' "$f" | sed 's/"key":"//;s/"$//')
        local ts=$(grep -o '"timestamp":"[^"]*"' "$f" | sed 's/"timestamp":"//;s/"$//')
        echo "[$ts] $key"
    done
}

# 删除记忆
delete_memory() {
    local key="$1"
    local id=$(echo "$key" | md5sum | cut -c1-8)
    
    if [ -f "$MEMORY_DIR/${id}.json" ]; then
        rm -f "$MEMORY_DIR/${id}.json"
        echo "✓ 记忆已删除: $key"
    else
        echo "错误: 记忆不存在: $key"
    fi
}

# 清空记忆
clear_memory() {
    rm -f "$MEMORY_DIR"/*.json
    init_index
    echo "✓ 所有记忆已清空"
}

# 主入口
case "$ACTION" in
    save|set)
        KEY=$(echo "$ARGS" | cut -d' ' -f1)
        VALUE=$(echo "$ARGS" | cut -d' ' -f2-)
        save_memory "$KEY" "$VALUE"
        ;;
    search|find|recall)
        search_memory "$ARGS"
        ;;
    list|ls)
        list_memory
        ;;
    delete|rm)
        delete_memory "$ARGS"
        ;;
    clear)
        clear_memory
        ;;
    *)
        echo "用法: memory.sh <action> [args]"
        echo "Actions: save, search, list, delete, clear"
        echo ""
        echo "示例:"
        echo "  memory.sh save my_key '这是一条记忆'"
        echo "  memory.sh search '关键词'"
        echo "  memory.sh list"
        exit 1
        ;;
esac
