#!/system/bin/sh
# MiMo Master Tool Dispatcher
# 统一入口，路由到各个工具脚本

TOOLS_DIR="/data/adb/mimo/tools"
CONFIG_FILE="/data/adb/mimo/config/mimo_mode.json"

# 从配置读取 API 信息
if [ -f "$CONFIG_FILE" ]; then
    MIMO_API=$(grep -o '"url":"[^"]*"' "$CONFIG_FILE" | sed 's/"url":"//;s/"$//')
    MIMO_TOKEN=$(grep -o '"token":"[^"]*"' "$CONFIG_FILE" | sed 's/"token":"//;s/"$//')
fi
MIMO_API="${MIMO_API:-https://api.mi.com/v1}"

# 构建 curl 认证参数
AUTH_HEADER=""
if [ -n "$MIMO_TOKEN" ]; then
    AUTH_HEADER="-H \"Authorization: Bearer $MIMO_TOKEN\""
fi

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

TOOL="$1"
shift
ARGS="$*"

case "$TOOL" in
    # === 网络工具 ===
    search|web_search)
        "$TOOLS_DIR/web_search.sh" $ARGS
        ;;
    fetch|web_fetch)
        "$TOOLS_DIR/web_fetch.sh" $ARGS
        ;;
    weather)
        "$TOOLS_DIR/weather.sh" $ARGS
        ;;
    
    # === 文件操作 ===
    read|cat)
        "$TOOLS_DIR/file_ops.sh" read $ARGS
        ;;
    write)
        "$TOOLS_DIR/file_ops.sh" write $ARGS
        ;;
    edit)
        "$TOOLS_DIR/file_ops.sh" edit $ARGS
        ;;
    ls|list)
        "$TOOLS_DIR/file_ops.sh" ls $ARGS
        ;;
    mkdir)
        "$TOOLS_DIR/file_ops.sh" mkdir $ARGS
        ;;
    rm|delete)
        "$TOOLS_DIR/file_ops.sh" rm $ARGS
        ;;
    cp|copy)
        "$TOOLS_DIR/file_ops.sh" cp $ARGS
        ;;
    mv|move)
        "$TOOLS_DIR/file_ops.sh" mv $ARGS
        ;;
    find)
        "$TOOLS_DIR/file_ops.sh" find $ARGS
        ;;
    grep)
        "$TOOLS_DIR/file_ops.sh" grep $ARGS
        ;;
    
    # === Shell 执行 ===
    exec|shell|run)
        "$TOOLS_DIR/shell_exec.sh" $ARGS
        ;;
    
    # === 代码执行 ===
    code|python|node|ruby|lua)
        "$TOOLS_DIR/code_exec.sh" $TOOL $ARGS
        ;;
    
    # === 记忆系统 ===
    memory|mem)
        "$TOOLS_DIR/memory.sh" $ARGS
        ;;
    
    # === 定时任务 ===
    cron|schedule)
        "$TOOLS_DIR/cron_tool.sh" $ARGS
        ;;
    
    # === 设备控制 ===
    device|phone)
        "$TOOLS_DIR/device.sh" $ARGS
        ;;
    
    # === 多模态 ===
    image|audio|video|ocr|multimodal)
        "$TOOLS_DIR/multimodal.sh" $TOOL $ARGS
        ;;
    
    # === 文档处理 ===
    excel|word|pptx|pdf|csv|document)
        "$TOOLS_DIR/document.sh" $ARGS
        ;;
    
    # === 设计工具 ===
    design|frontend|svg|chart|draw)
        "$TOOLS_DIR/design.sh" $TOOL $ARGS
        ;;
    
    # === 写作助手 ===
    write_content|summarize|translate|rewrite)
        "$TOOLS_DIR/writing.sh" $TOOL $ARGS
        ;;
    
    # === 数据科学 ===
    data|analyze|model|visualize)
        "$TOOLS_DIR/datascience.sh" $TOOL $ARGS
        ;;
    
    # === GitHub ===
    gh|github)
        "$TOOLS_DIR/github.sh" $ARGS
        ;;
    
    # === AI 对话 ===
    chat|ask|tell)
        echo -n "🤖 MiMo > "
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \\
            -H "Authorization: Bearer $MIMO_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"user\", \"content\": \"$ARGS\"}
                ],
                \"max_tokens\": 4096,
                \"temperature\": 0.7
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    # === 代码生成 ===
    code_gen|generate)
        echo "💻 代码生成..."
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \\
            -H "Authorization: Bearer $MIMO_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"你是编程专家。直接输出代码，使用 markdown 代码块。\"},
                    {\"role\": \"user\", \"content\": \"$ARGS\"}
                ],
                \"max_tokens\": 8192,
                \"temperature\": 0.3
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    # === 推理/思考 ===
    think|reason)
        echo "🧠 思考中..."
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \\
            -H "Authorization: Bearer $MIMO_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"你是深度思考专家。逐步推理，分析问题的各个方面，给出有深度的见解。\"},
                    {\"role\": \"user\", \"content\": \"$ARGS\"}
                ],
                \"max_tokens\": 8192,
                \"temperature\": 0.5
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    # === 翻译 ===
    trans)
        echo "🌐 翻译..."
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \\
            -H "Authorization: Bearer $MIMO_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"翻译以下内容。如果输入是中文，翻译成英文；如果输入是其他语言，翻译成中文。保持原意。\"},
                    {\"role\": \"user\", \"content\": \"$ARGS\"}
                ],
                \"max_tokens\": 4096
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
    
    # === 帮助 ===
    help|--help|-h)
        echo -e "${BOLD}MiMo v2.5 Pro - 技能工具箱${NC}"
        echo ""
        echo -e "${CYAN}🤖 AI 对话${NC}"
        echo "  mimo chat <message>      对话"
        echo "  mimo ask <question>      提问"
        echo "  mimo think <problem>     深度思考"
        echo "  mimo code_gen <task>     代码生成"
        echo "  mimo trans <text>        智能翻译"
        echo ""
        echo -e "${CYAN}🌐 网络${NC}"
        echo "  mimo search <query>      搜索网络"
        echo "  mimo fetch <url>         抓取网页"
        echo "  mimo weather <location>  查天气"
        echo ""
        echo -e "${CYAN}📁 文件${NC}"
        echo "  mimo read <file>         读文件"
        echo "  mimo write <file> <text> 写文件"
        echo "  mimo ls <dir>            列目录"
        echo "  mimo find <dir> <name>   查找文件"
        echo "  mimo grep <dir> <text>   搜索内容"
        echo ""
        echo -e "${CYAN}💻 执行${NC}"
        echo "  mimo exec <command>      执行命令"
        echo "  mimo python <code>       运行 Python"
        echo "  mimo node <code>         运行 Node.js"
        echo ""
        echo -e "${CYAN}🧠 记忆${NC}"
        echo "  mimo memory save <k> <v> 保存记忆"
        echo "  mimo memory search <q>   搜索记忆"
        echo "  mimo memory list         列出记忆"
        echo ""
        echo -e "${CYAN}⏰ 定时${NC}"
        echo "  mimo cron add <sch> <t>  添加任务"
        echo "  mimo cron list           列出任务"
        echo ""
        echo -e "${CYAN}📱 设备${NC}"
        echo "  mimo device info         设备信息"
        echo "  mimo device battery      电池状态"
        echo "  mimo device screenshot   截图"
        echo "  mimo device record       录屏"
        echo ""
        echo -e "${CYAN}🖼️ 多模态${NC}"
        echo "  mimo image <file>        分析图片"
        echo "  mimo ocr <file>          图片OCR"
        echo "  mimo audio <file>        转录音频"
        echo "  mimo video <file>        分析视频"
        echo ""
        echo -e "${CYAN}📊 文档${NC}"
        echo "  mimo excel create <file> 创建Excel"
        echo "  mimo word create <file>  创建Word"
        echo "  mimo pptx create <file>  创建PPT"
        echo ""
        echo -e "${CYAN}🎨 设计${NC}"
        echo "  mimo design frontend <s> 生成前端"
        echo "  mimo design svg <spec>   SVG绘图"
        echo "  mimo design chart <data> 生成图表"
        echo ""
        echo -e "${CYAN}✍️ 写作${NC}"
        echo "  mimo write_content <spec> 写内容"
        echo "  mimo summarize <text>    总结"
        echo "  mimo translate <text>    翻译"
        echo ""
        echo -e "${CYAN}📊 数据${NC}"
        echo "  mimo data analyze <file> 分析数据"
        echo "  mimo data model <file>   训练模型"
        echo "  mimo data visualize <f>  数据可视化"
        echo ""
        echo -e "${CYAN}🔧 GitHub${NC}"
        echo "  mimo gh issue            Issues"
        echo "  mimo gh pr               Pull Requests"
        echo "  mimo gh repo             仓库管理"
        ;;
    
    *)
        # 默认当作对话处理
        curl -s -X POST "${MIMO_API}/v1/chat/completions" \\
            -H "Authorization: Bearer $MIMO_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"user\", \"content\": \"$TOOL $ARGS\"}
                ],
                \"max_tokens\": 4096,
                \"temperature\": 0.7
            }" 2>/dev/null | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
        ;;
esac
