#!/system/bin/sh
# MiMo Tool: Weather
# 用法: weather.sh <location>

LOCATION="$*"

if [ -z "$LOCATION" ]; then
    echo "错误: 请提供位置"
    echo "用法: weather.sh 北京"
    exit 1
fi

# 使用 wttr.in
echo "🌤️ 天气: $LOCATION"
echo "---"
curl -s "wttr.in/${LOCATION}?format=v2&lang=zh" --max-time 15 2>/dev/null

if [ $? -ne 0 ]; then
    # 备用: 简洁格式
    curl -s "wttr.in/${Location}?lang=zh" --max-time 15 2>/dev/null
fi
