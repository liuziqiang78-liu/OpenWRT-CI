#!/system/bin/sh
# MiMo Tool: Web Fetch
# 用法: web_fetch.sh <url> [max_chars]

URL="$1"
MAX_CHARS="${2:-5000}"
OUTPUT_MODE="${3:-text}"  # text or html

if [ -z "$URL" ]; then
    echo "错误: 请提供 URL"
    echo "用法: web_fetch.sh <url> [max_chars] [text|html]"
    exit 1
fi

# 抓取内容
CONTENT=$(curl -s -L "$URL" \
    -H "User-Agent: Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36" \
    -H "Accept: text/html,application/xhtml+xml" \
    --max-time 30 2>/dev/null)

if [ -z "$CONTENT" ]; then
    echo "错误: 无法获取 $URL"
    exit 1
fi

if [ "$OUTPUT_MODE" = "html" ]; then
    echo "$CONTENT" | head -c "$MAX_CHARS"
else
    # 提取纯文本
    echo "$CONTENT" | \
        sed 's/<script[^>]*>.*<\/script>//g' | \
        sed 's/<style[^>]*>.*<\/style>//g' | \
        sed 's/<[^>]*>//g' | \
        sed 's/&nbsp;/ /g' | \
        sed 's/&lt;/</g' | \
        sed 's/&gt;/>/g' | \
        sed 's/&amp;/\&/g' | \
        sed 's/^[[:space:]]*//' | \
        sed '/^$/d' | \
        head -c "$MAX_CHARS"
fi
