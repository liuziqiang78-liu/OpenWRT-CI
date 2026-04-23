#!/system/bin/sh
# MiMo Tool: Web Search
# 用法: web_search.sh <query>

QUERY="$*"
CACHE_DIR="/data/adb/mimo/cache/search"
mkdir -p "$CACHE_DIR"

# 多搜索引擎支持
search_ddg() {
    local encoded=$(echo "$QUERY" | sed 's/ /+/g')
    curl -s -L "https://html.duckduckgo.com/html/?q=${encoded}" \
        -H "User-Agent: Mozilla/5.0" \
        --max-time 15 2>/dev/null | \
        sed -n 's/.*class="result__a"[^>]*href="\([^"]*\)".*/\1/p' | head -5
}

search_searx() {
    local encoded=$(echo "$QUERY" | sed 's/ /+/g')
    curl -s "https://searx.be/search?q=${encoded}&format=json" \
        --max-time 15 2>/dev/null | \
        grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"$//' | head -5
}

# 执行搜索
echo "🔍 搜索: $QUERY"
echo "---"

RESULTS=$(search_ddg)
if [ -z "$RESULTS" ]; then
    RESULTS=$(search_searx)
fi

if [ -n "$RESULTS" ]; then
    echo "$RESULTS" | while read -r url; do
        echo "• $url"
    done
else
    echo "未找到结果"
fi
