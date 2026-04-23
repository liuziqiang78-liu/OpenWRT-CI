#!/system/bin/sh
# MiMo Tool: Device Control
# 用法: device.sh <action> [args...]

ACTION="$1"
shift
ARGS="$*"

case "$ACTION" in
    info|status)
        echo "📱 设备信息:"
        echo "---"
        echo "型号: $(getprop ro.product.model)"
        echo "品牌: $(getprop ro.product.brand)"
        echo "Android: $(getprop ro.build.version.release)"
        echo "SDK: $(getprop ro.build.version.sdk)"
        echo "架构: $(getprop ro.product.cpu.abi)"
        echo "内核: $(uname -r)"
        echo "内存: $(cat /proc/meminfo | grep MemTotal | awk '{print int($2/1024)"MB"}')"
        echo "存储: $(df /data | tail -1 | awk '{print int($4/1024)"MB 可用"}')"
        echo "电量: $(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo '未知')%"
        echo "温度: $(cat /sys/class/power_supply/battery/temp 2>/dev/null | awk '{print $1/10"°C"}' || echo '未知')"
        ;;
    battery)
        echo "🔋 电池状态:"
        echo "---"
        echo "电量: $(cat /sys/class/power_supply/battery/capacity 2>/dev/null)%"
        echo "状态: $(cat /sys/class/power_supply/battery/status 2>/dev/null)"
        echo "温度: $(cat /sys/class/power_supply/battery/temp 2>/dev/null | awk '{print $1/10"°C"}')"
        echo "电压: $(cat /sys/class/power_supply/battery/voltage 2>/dev/null | awk '{print $1/1000"V"}')"
        ;;
    network)
        echo "🌐 网络状态:"
        echo "---"
        echo "WiFi: $(dumpsys connectivity | grep 'NetworkAgentInfo' | head -1)"
        echo "IP: $(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}')"
        echo "DNS: $(getprop net.dns1)"
        ;;
    cpu)
        echo "💻 CPU 信息:"
        echo "---"
        echo "核心数: $(nproc)"
        echo "频率: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null | awk '{print $1/1000"MHz"}')"
        echo "使用率: $(top -bn1 | head -5 | grep 'CPU' | awk '{print $2}')"
        ;;
    gpu)
        echo "🎮 GPU 信息:"
        echo "---"
        getprop | grep -i gpu
        ;;
    sensors)
        echo "📡 传感器:"
        echo "---"
        cat /proc/bus/input/devices 2>/dev/null | grep -E "Name|Handlers" | paste - - | head -10
        ;;
    storage)
        echo "💾 存储:"
        echo "---"
        df -h /data /system /cache 2>/dev/null
        ;;
    process)
        echo "⚙️ 进程 (Top 10):"
        echo "---"
        ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -11
        ;;
    screenshot)
        SCREENSHOT_PATH="/data/adb/mimo/cache/screenshot_$(date +%Y%m%d_%H%M%S).png"
        screencap -p "$SCREENSHOT_PATH"
        echo "📸 截图已保存: $SCREENSHOT_PATH"
        ;;
    record)
        DURATION="${ARGS:-10}"
        RECORD_PATH="/data/adb/mimo/cache/record_$(date +%Y%m%d_%H%M%S).mp4"
        echo "🎬 录屏 ${DURATION}s..."
        screenrecord --time-limit "$DURATION" "$RECORD_PATH"
        echo "✓ 录屏已保存: $RECORD_PATH"
        ;;
    clipboard)
        if [ -n "$ARGS" ]; then
            echo "$ARGS" | termux-clipboard-set 2>/dev/null || echo "$ARGS" > /dev/clipboard
            echo "📋 已复制到剪贴板"
        else
            termux-clipboard-get 2>/dev/null || cat /dev/clipboard 2>/dev/null
        fi
        ;;
    notification)
        if [ -n "$ARGS" ]; then
            # 需要 Termux:API
            termux-notification --title "MiMo" --content "$ARGS" 2>/dev/null
            echo "🔔 通知已发送"
        fi
        ;;
    vibrate)
        termux-vibrate 2>/dev/null
        echo "📳 振动"
        ;;
    flashlight)
        if command -v termux-torch > /dev/null 2>&1; then
            termux-torch on 2>/dev/null
            echo "🔦 手电筒已开启"
        fi
        ;;
    location)
        echo "📍 位置:"
        termux-location 2>/dev/null || echo "需要 Termux:API"
        ;;
    *)
        echo "用法: device.sh <action> [args]"
        echo "Actions: info, battery, network, cpu, gpu, sensors, storage, process"
        echo "         screenshot, record, clipboard, notification, vibrate, flashlight, location"
        exit 1
        ;;
esac
