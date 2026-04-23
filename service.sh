#!/system/bin/sh
# MiMo v2.5 Pro AI Module - service
# 云端 API 模式

MODDIR=${0%/*}
MIMO_DIR="/data/adb/mimo"
MIMO_CACHE="/data/cache/mimo"
CONFIG_FILE="$MIMO_DIR/config/mimo_mode.json"
LOG_FILE="$MIMO_DIR/mimo_service.log"

WEBUI_PORT=9081

# 确保目录存在
mkdir -p "$MIMO_DIR" "$MIMO_CACHE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== MiMo v2.5 Pro Service 启动 ==="

# 等待系统完全启动
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
sleep 5

log "系统启动完成"

# 读取云端配置
if [ -f "$CONFIG_FILE" ]; then
    MODE=$(grep -o '"mode":"[^"]*"' "$CONFIG_FILE" | sed 's/"mode":"//;s/"$//')
    API_URL=$(grep -o '"url":"[^"]*"' "$CONFIG_FILE" | sed 's/"url":"//;s/"$//')
    API_TOKEN=$(grep -o '"token":"[^"]*"' "$CONFIG_FILE" | sed 's/"token":"//;s/"$//')
    log "模式: $MODE | API: $API_URL"
else
    MODE="cloud"
    API_URL="https://api.mi.com/v1"
    API_TOKEN=""
    log "无配置文件，请运行 mimo_config 设置 Token"
fi

if [ "$MODE" != "cloud" ] || [ -z "$API_TOKEN" ]; then
    log "未配置云端 API Token，启动配置向导..."
    # 仍然启动 WebUI，让用户可以在界面中配置
fi

# 测试 API 连接
if [ -n "$API_TOKEN" ]; then
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $API_TOKEN" \
        "$API_URL/models" --max-time 10 2>/dev/null)
    log "API 连接测试: HTTP $RESPONSE"
fi

# 启动 WebUI
WEBUI_DIR="$MIMO_DIR/webui"
PYTHON=$(command -v python3 || command -v python)
if [ -f "$WEBUI_DIR/server.py" ] && [ -n "$PYTHON" ]; then
    log "启动 WebUI (端口: $WEBUI_PORT)..."
    export MIMO_API="$API_URL"
    export MIMO_TOKEN="$API_TOKEN"
    export MIMO_MODE="cloud"
    nohup "$PYTHON" "$WEBUI_DIR/server.py" "$WEBUI_PORT" \
        >> "$LOG_FILE" 2>&1 &
    WEBUI_PID=$!
    log "WebUI 已启动 (PID: $WEBUI_PID)"
    echo "$WEBUI_PID" > "$MIMO_DIR/webui.pid"
    log "地址: http://localhost:$WEBUI_PORT"
fi

setprop persist.mimo.mode cloud
setprop persist.mimo.enabled true
setprop persist.mimo.port "$WEBUI_PORT"

log "=== Service 启动完成 ==="
