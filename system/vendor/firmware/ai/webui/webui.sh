#!/system/bin/sh
# MiMo WebUI 启动脚本
# 用法: webui.sh [端口] (默认 9081)

PORT="${1:-9081}"
WEBUI_DIR="/data/adb/mimo/webui"

PYTHON=$(command -v python3 || command -v python)
if [ -z "$PYTHON" ]; then
    echo "❌ 需要 Python"
    echo "安装: pkg install python"
    exit 1
fi

echo ""
echo "🚀 MiMo WebUI"
echo "   地址: http://localhost:${PORT}"
echo "   按 Ctrl+C 停止"
echo ""

cd "$WEBUI_DIR"
exec $PYTHON server.py "$PORT"
