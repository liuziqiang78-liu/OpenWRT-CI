#!/sbin/sh

#################
# Initialization
#################

MODDIR=${0%/*}
. /data/adb/apatch/util_functions.sh

MODULE_ID="apatch-mimo-v2.5-pro"
MODULE_NAME="MiMo v2.5 Pro AI Module"
MODULE_VERSION="v2.5.0"

MIMO_DIR="/data/adb/mimo"
MIMO_CACHE="/data/cache/mimo"
WEBUI_PORT=9081

DEVICE_MODEL=$(getprop ro.product.model)
ANDROID_VER=$(getprop ro.build.version.release)
SDK_VER=$(getprop ro.build.version.sdk)
ABI=$(getprop ro.product.cpu.abi)

ui_print "╔══════════════════════════════════════╗"
ui_print "║  Xiaomi MiMo v2.5 Pro AI Module      ║"
ui_print "║  Cloud API Mode                      ║"
ui_print "╚══════════════════════════════════════╝"
ui_print ""

# 设备兼容性检查
check_device() {
    ui_print "- 检查设备..."
    
    if [ "$SDK_VER" -lt 30 ]; then
        ui_print "  ✗ 需要 Android 11+"
        abort "  当前: Android $ANDROID_VER"
    fi
    ui_print "  ✓ Android $ANDROID_VER"
    
    TOTAL_RAM=$(cat /proc/meminfo | grep MemTotal | awk '{print int($2/1024)}')
    ui_print "  ✓ 内存: ${TOTAL_RAM}MB"
    
    AVAIL_SPACE=$(df /data | tail -1 | awk '{print int($4/1024)}')
    if [ "$AVAIL_SPACE" -lt 500 ]; then
        ui_print "  ✗ 存储空间不足 (需要 500MB+)"
        abort
    fi
    ui_print "  ✓ 存储: ${AVAIL_SPACE}MB 可用"
}

# 创建目录
setup_dirs() {
    ui_print "- 创建目录..."
    mkdir -p "$MIMO_DIR/config"
    mkdir -p "$MIMO_DIR/tools"
    mkdir -p "$MIMO_DIR/skills"
    mkdir -p "$MIMO_DIR/prompts"
    mkdir -p "$MIMO_DIR/webui"
    mkdir -p "$MIMO_DIR/memory"
    mkdir -p "$MIMO_DIR/workspace"
    mkdir -p "$MIMO_DIR/cache"
    mkdir -p "$MIMO_DIR/bin"
    mkdir -p "$MIMO_CACHE"
    ui_print "  ✓ 目录已创建"
}

# 安装工具
install_tools() {
    ui_print "- 安装工具..."
    
    cp -rf "$MODDIR/system/vendor/firmware/ai/tools/"* "$MIMO_DIR/tools/" 2>/dev/null
    chmod 755 "$MIMO_DIR/tools/"*.sh 2>/dev/null
    
    cp -rf "$MODDIR/system/vendor/firmware/ai/skills/"* "$MIMO_DIR/skills/" 2>/dev/null
    cp -rf "$MODDIR/system/vendor/firmware/ai/prompts/"* "$MIMO_DIR/prompts/" 2>/dev/null
    cp -f "$MODDIR/system/vendor/firmware/ai/mimo_agent_config.json" "$MIMO_DIR/config/" 2>/dev/null
    cp -f "$MODDIR/system/vendor/firmware/ai/mimo_config.json" "$MIMO_DIR/config/" 2>/dev/null
    
    cp -rf "$MODDIR/system/vendor/firmware/ai/webui/"* "$MIMO_DIR/webui/" 2>/dev/null
    chmod 755 "$MIMO_DIR/webui/"*.sh 2>/dev/null
    chmod 755 "$MIMO_DIR/webui/"*.py 2>/dev/null
    
    cp -f "$MODDIR/system/vendor/bin/mimo_chat.sh" "$MIMO_DIR/bin/" 2>/dev/null
    chmod 755 "$MIMO_DIR/bin/mimo_chat.sh" 2>/dev/null
    
    ln -sf "$MIMO_DIR/tools/mimo_config.sh" "/system/vendor/bin/mimo_config" 2>/dev/null
    ln -sf "$MIMO_DIR/webui/webui.sh" "/system/vendor/bin/mimo_webui" 2>/dev/null
    
    ui_print "  ✓ 工具已安装"
}

# 写入默认配置
write_config() {
    ui_print "- 写入配置..."
    
    cat > "$MIMO_DIR/config/mimo_mode.json" << EOF
{
    "mode": "cloud",
    "api": {
        "url": "https://api.mi.com/v1",
        "token": "",
        "model": "mimo-v2.5-pro"
    },
    "updated": "$(date -Iseconds)"
}
EOF
    
    ui_print "  ✓ 配置已写入"
    ui_print ""
    ui_print "  ⚠️  首次使用请运行: mimo_config"
    ui_print "     设置 API Token"
}

# 主流程
check_device
setup_dirs

# 检查 Python
PYTHON=$(command -v python3 || command -v python)
if [ -z "$PYTHON" ]; then
    ui_print ""
    ui_print "⚠️  Python 未安装"
    ui_print "  WebUI 需要 Python，请安装后运行:"
    ui_print "  pkg install python"
    ui_print ""
fi

install_tools
write_config

ui_print ""
ui_print "╔══════════════════════════════════════╗"
ui_print "║  安装完成!                            ║"
ui_print "╠══════════════════════════════════════╣"
ui_print "║  模式: 云端 API                       ║"
ui_print "║  WebUI: http://localhost:9081         ║"
ui_print "║  命令: mimo_config (设置 Token)       ║"
ui_print "╚══════════════════════════════════════╝"
ui_print ""
ui_print "使用步骤:"
ui_print "  1. 重启设备"
ui_print "  2. 终端运行: mimo_config"
ui_print "  3. 输入 API Token"
ui_print "  4. 浏览器打开: http://localhost:9081"
