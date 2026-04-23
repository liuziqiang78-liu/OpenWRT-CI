#!/system/bin/sh
# MiMo Tool: Cron Scheduler
# 用法: cron_tool.sh <action> [args...]

CRON_DIR="/data/adb/mimo/cron"
CRON_JOBS="$CRON_DIR/jobs.json"
mkdir -p "$CRON_DIR"

ACTION="$1"
shift
ARGS="$*"

init_jobs() {
    if [ ! -f "$CRON_JOBS" ]; then
        echo '{"jobs":{}}' > "$CRON_JOBS"
    fi
}

# 添加定时任务
add_job() {
    local schedule="$1"
    local task="$2"
    local name="${3:-unnamed}"
    local id="job_$(date +%s)"
    local timestamp=$(date -Iseconds)
    
    init_jobs
    
    cat > "$CRON_DIR/${id}.json" << EOF
{
    "id": "$id",
    "name": "$name",
    "schedule": "$schedule",
    "task": "$task",
    "enabled": true,
    "created": "$timestamp",
    "last_run": null,
    "run_count": 0
}
EOF
    
    # 添加到 crontab
    local cron_line="$schedule /data/adb/mimo/tools/cron_tool.sh run $id"
    
    # 合并到系统 crontab
    (crontab -l 2>/dev/null | grep -v "$id"; echo "$cron_line") | crontab -
    
    echo "✓ 定时任务已添加: $name"
    echo "  ID: $id"
    echo "  计划: $schedule"
    echo "  任务: $task"
}

# 列出任务
list_jobs() {
    echo "⏰ 定时任务:"
    echo "---"
    
    init_jobs
    
    for f in "$CRON_DIR"/job_*.json; do
        [ ! -f "$f" ] && continue
        local id=$(grep -o '"id":"[^"]*"' "$f" | sed 's/"id":"//;s/"$//')
        local name=$(grep -o '"name":"[^"]*"' "$f" | sed 's/"name":"//;s/"$//')
        local schedule=$(grep -o '"schedule":"[^"]*"' "$f" | sed 's/"schedule":"//;s/"$//')
        local enabled=$(grep -o '"enabled":[^,]*' "$f" | sed 's/"enabled"://')
        echo "[$enabled] $id: $name ($schedule)"
    done
}

# 运行任务
run_job() {
    local id="$1"
    local job_file="$CRON_DIR/${id}.json"
    
    if [ ! -f "$job_file" ]; then
        echo "错误: 任务不存在: $id"
        exit 1
    fi
    
    local task=$(grep -o '"task":"[^"]*"' "$job_file" | sed 's/"task":"//;s/"$//')
    local name=$(grep -o '"name":"[^"]*"' "$job_file" | sed 's/"name":"//;s/"$//')
    
    echo "⏰ 执行任务: $name"
    echo "---"
    
    # 执行任务
    eval "$task"
    
    # 更新运行记录
    local count=$(grep -o '"run_count":[0-9]*' "$job_file" | sed 's/"run_count"://')
    count=$((count + 1))
    sed -i "s/\"run_count\":[0-9]*/\"run_count\":$count/" "$job_file"
    sed -i "s/\"last_run\":null/\"last_run\":\"$(date -Iseconds)\"/" "$job_file"
}

# 删除任务
delete_job() {
    local id="$1"
    local job_file="$CRON_DIR/${id}.json"
    
    if [ -f "$job_file" ]; then
        rm -f "$job_file"
        # 从 crontab 移除
        crontab -l 2>/dev/null | grep -v "$id" | crontab -
        echo "✓ 任务已删除: $id"
    else
        echo "错误: 任务不存在: $id"
    fi
}

# 启用/禁用任务
toggle_job() {
    local id="$1"
    local enabled="$2"
    local job_file="$CRON_DIR/${id}.json"
    
    if [ -f "$job_file" ]; then
        sed -i "s/\"enabled\":[^,]*/\"enabled\":$enabled/" "$job_file"
        echo "✓ 任务已${enabled:+启用}${enabled:-禁用}: $id"
    fi
}

# 主入口
case "$ACTION" in
    add|create)
        # ARGS: "schedule" "task" ["name"]
        SCHEDULE=$(echo "$ARGS" | cut -d'"' -f2)
        TASK=$(echo "$ARGS" | cut -d'"' -f4)
        NAME=$(echo "$ARGS" | cut -d'"' -f6)
        add_job "$SCHEDULE" "$TASK" "$NAME"
        ;;
    list|ls)
        list_jobs
        ;;
    run|exec)
        run_job "$ARGS"
        ;;
    delete|rm)
        delete_job "$ARGS"
        ;;
    enable)
        toggle_job "$ARGS" "true"
        ;;
    disable)
        toggle_job "$ARGS" "false"
        ;;
    *)
        echo "用法: cron_tool.sh <action> [args]"
        echo "Actions: add, list, run, delete, enable, disable"
        exit 1
        ;;
esac
