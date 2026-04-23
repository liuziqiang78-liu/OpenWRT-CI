#!/system/bin/sh
# MiMo v2.5 Pro AI Module - 卸载脚本

MIMO_DIR="/data/adb/mimo"
LOG_FILE="$MIMO_DIR/mimo_service.log"

# 确保日志目录存在
mkdir -p "$MIMO_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === MiMo v2.5 Pro 卸载开始 ===" >> "$LOG_FILE"

# 停止 WebUI 服务器
if [ -f "$MIMO_DIR/webui.pid" ]; then
    PID=$(cat "$MIMO_DIR/webui.pid")
    if [ -n "$PID" ]; then
        kill "$PID" 2>/dev/null
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 已停止 WebUI (PID: $PID)" >> "$LOG_FILE"
    fi
    rm -f "$MIMO_DIR/webui.pid"
fi

# 清理系统属性
for prop in \
    persist.mimo.enabled \
    persist.mimo.mode \
    persist.mimo.port \
    persist.mimo.version \
    persist.mimo.model \
    persist.mimo.api.url; do
    resetprop --delete "$prop" 2>/dev/null
done

# 清理缓存
rm -rf /data/cache/mimo 2>/dev/null

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === 卸载完成 ===" >> "$LOG_FILE"
echo "如需完全删除数据，请手动执行: rm -rf $MIMO_DIR"
