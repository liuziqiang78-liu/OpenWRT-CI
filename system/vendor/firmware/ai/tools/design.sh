#!/system/bin/sh
# MiMo Tool: Design & Frontend
# 用法: design.sh <action> <spec>

ACTION="$1"
shift
SPEC="$*"

MIMO_API="http://localhost:8080"

case "$ACTION" in
    frontend|generate)
        echo "🎨 生成前端界面..."
        echo "---"
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"你是前端开发专家。生成完整的 HTML/CSS/JS 代码，可以直接在浏览器中运行。使用现代设计风格，注重细节和动画。\"},
                    {\"role\": \"user\", \"content\": \"生成一个前端界面: ${SPEC}\"}
                ],
                \"max_tokens\": 8192,
                \"temperature\": 0.3
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    critique|review)
        echo "🔍 设计评审..."
        echo "---"
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"你是 UX 设计评审专家。评估设计的质量，包括视觉层次、信息架构、用户体验、可访问性。提供具体的改进建议。\"},
                    {\"role\": \"user\", \"content\": \"评审这个设计: ${SPEC}\"}
                ],
                \"max_tokens\": 4096
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    polish|improve)
        echo "✨ 设计优化..."
        echo "---"
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"你是设计优化专家。保持设计核心意图的同时，优化细节：对齐、间距、颜色、字体、动画。输出完整代码。\"},
                    {\"role\": \"user\", \"content\": \"优化这个设计: ${SPEC}\"}
                ],
                \"max_tokens\": 8192,
                \"temperature\": 0.3
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    svg|draw)
        echo "🎨 SVG 绘图..."
        echo "---"
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"生成 SVG 图片代码。直接输出 SVG 代码，不要解释。使用 viewBox 适配不同尺寸。\"},
                    {\"role\": \"user\", \"content\": \"绘制: ${SPEC}\"}
                ],
                \"max_tokens\": 4096,
                \"temperature\": 0.3
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    chart)
        echo "📊 图表生成..."
        echo "---"
        
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"生成图表配置。输出 JSON 格式的图表配置，支持 ECharts。\"},
                    {\"role\": \"user\", \"content\": \"生成图表: ${SPEC}\"}
                ],
                \"max_tokens\": 4096,
                \"temperature\": 0.3
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    *)
        echo "用法: design.sh <action> <spec>"
        echo "Actions: frontend, critique, polish, svg, chart"
        exit 1
        ;;
esac
