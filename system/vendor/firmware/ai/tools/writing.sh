#!/system/bin/sh
# MiMo Tool: Writing Assistant
# 用法: writing.sh <action> <spec>

ACTION="$1"
shift
SPEC="$*"

MIMO_API="http://localhost:8080"

case "$ACTION" in
    write|create)
        echo "✍️ 内容创作..."
        echo "---"
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"你是专业的内容创作者。根据需求创作高质量内容。注意：结构清晰、逻辑连贯、语言精练。输出 markdown 格式。\"},
                    {\"role\": \"user\", \"content\": \"创作内容: ${SPEC}\"}
                ],
                \"max_tokens\": 8192,
                \"temperature\": 0.7
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    summarize|summary)
        echo "📝 内容总结..."
        echo "---"
        
        # 检查是否是 URL
        if echo "$SPEC" | grep -qE "^https?://"; then
            # 先抓取网页内容
            CONTENT=$(curl -s -L "$SPEC" --max-time 30 | sed 's/<[^>]*>//g' | head -c 10000)
        else
            CONTENT="$SPEC"
        fi
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"总结内容，提取核心要点。输出结构化的摘要，包括：主要观点、关键信息、结论。\"},
                    {\"role\": \"user\", \"content\": \"总结以下内容: ${CONTENT}\"}
                ],
                \"max_tokens\": 4096
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    translate)
        echo "🌐 翻译..."
        echo "---"
        
        # 从 SPEC 中提取目标语言
        TARGET_LANG=$(echo "$SPEC" | grep -oE "(中文|英文|日文|韩文|法文|德文|西班牙文|Chinese|English|Japanese|Korean|French|German|Spanish)" | head -1)
        TEXT=$(echo "$SPEC" | sed "s/$TARGET_LANG//g" | sed 's/^[[:space:]]*//')
        
        if [ -z "$TARGET_LANG" ]; then
            TARGET_LANG="中文"
        fi
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"你是专业翻译。将内容翻译成${TARGET_LANG}。保持原意，语言自然流畅。\"},
                    {\"role\": \"user\", \"content\": \"翻译: ${TEXT}\"}
                ],
                \"max_tokens\": 4096
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    rewrite|improve)
        echo "✏️ 内容优化..."
        echo "---"
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"优化文本质量。改进：语法、表达、结构、逻辑。保持原意，提升可读性。\"},
                    {\"role\": \"user\", \"content\": \"优化这段文字: ${SPEC}\"}
                ],
                \"max_tokens\": 4096
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    expand|extend)
        echo "📖 内容扩展..."
        echo "---"
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"扩展和丰富内容。添加更多细节、例子、解释。保持主题一致。\"},
                    {\"role\": \"user\", \"content\": \"扩展这段内容: ${SPEC}\"}
                ],
                \"max_tokens\": 8192
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    *)
        echo "用法: writing.sh <action> <spec>"
        echo "Actions: write, summarize, translate, rewrite, expand"
        exit 1
        ;;
esac
