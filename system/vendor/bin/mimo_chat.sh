#!/system/bin/sh
# MiMo Chat CLI - 终端对话工具
# 使用方式: mimo_chat.sh [选项]

CONFIG_FILE="/data/adb/mimo/config/mimo_mode.json"

# 从配置读取 API 信息
if [ -f "$CONFIG_FILE" ]; then
    MIMO_API=$(grep -o '"url":"[^"]*"' "$CONFIG_FILE" | sed 's/"url":"//;s/"$//')
    MIMO_TOKEN=$(grep -o '"token":"[^"]*"' "$CONFIG_FILE" | sed 's/"token":"//;s/"$//')
fi
MIMO_API="${MIMO_API:-https://api.mi.com/v1}"

# 构建 curl 认证参数
CURL_AUTH=""
if [ -n "$MIMO_TOKEN" ]; then
    CURL_AUTH="-H Authorization:Bearer_$MIMO_TOKEN"
fi

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# 检查服务状态
check_service() {
    local auth_args=""
    if [ -n "$MIMO_TOKEN" ]; then
        auth_args="-H Authorization:Bearer_$MIMO_TOKEN"
    fi
    if ! curl -s $auth_args "${MIMO_API}/health" > /dev/null 2>&1; then
        echo -e "${RED}✗ MiMo API 未连接${NC}"
        echo -e "  API: ${MIMO_API}"
        echo -e "  运行 ${YELLOW}mimo_config${NC} 设置 Token"
        exit 1
    fi
    echo -e "${GREEN}✓ MiMo API 已连接${NC}"
}

# 发送消息并流式输出
chat_stream() {
    local message="$1"
    local max_tokens="${2:-1024}"
    local temperature="${3:-0.7}"
    
    # 构建请求
    local response=$(curl -s -X POST "${MIMO_API}/v1/chat/completions" \\
            -H "Authorization: Bearer $MIMO_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"messages\": [
                {\"role\": \"system\", \"content\": \"你是 MiMo，小米开发的 AI 助手。请用中文回答，保持简洁专业。\"},
                {\"role\": \"user\", \"content\": \"${message}\"}
            ],
            \"max_tokens\": ${max_tokens},
            \"temperature\": ${temperature},
            \"top_p\": 0.9,
            \"stream\": false
        }")
    
    # 解析并输出
    echo "$response" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
}

# 单次提问模式
ask_mode() {
    local question="$1"
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}MiMo v2.5 Pro${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    chat_stream "$question"
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# 交互式对话模式
interactive_mode() {
    echo -e "\n${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}MiMo v2.5 Pro Chat${NC}                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  输入消息开始对话                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  命令:                                 ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}    /clear  - 清空对话历史              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}    /temp N - 设置温度 (0.0-2.0)        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}    /quit   - 退出                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}\n"
    
    local temp=0.7
    local history=""
    local turn=0
    
    while true; do
        echo -ne "${GREEN}你 > ${NC}"
        read -r input
        
        # 空输入
        [ -z "$input" ] && continue
        
        # 命令处理
        case "$input" in
            /quit|/exit|/q)
                echo -e "\n${YELLOW}再见！${NC}\n"
                break
                ;;
            /clear)
                history=""
                turn=0
                echo -e "${YELLOW}对话已清空${NC}\n"
                continue
                ;;
            /temp*)
                temp=$(echo "$input" | awk '{print $2}')
                echo -e "${YELLOW}温度已设为: ${temp}${NC}\n"
                continue
                ;;
            /help)
                echo -e "${YELLOW}命令:${NC}"
                echo "  /clear  - 清空对话"
                echo "  /temp N - 设置温度"
                echo "  /quit   - 退出"
                continue
                ;;
        esac
        
        turn=$((turn + 1))
        
        # 构建消息
        history="${history}{\"role\":\"user\",\"content\":\"$(echo "$input" | sed 's/"/\\"/g')\"},"
        
        echo -ne "\n${BLUE}MiMo > ${NC}"
        
        # 发送请求
        local response=$(curl -s -X POST "${MIMO_API}/v1/chat/completions" \\
            -H "Authorization: Bearer $MIMO_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"messages\": [
                    {\"role\": \"system\", \"content\": \"你是 MiMo，小米开发的 AI 助手。请用中文回答，保持简洁专业。\"},
                    ${history}
                ],
                \"max_tokens\": 2048,
                \"temperature\": ${temp},
                \"top_p\": 0.9,
                \"stream\": false
            }")
        
        # 提取回复
        local reply=$(echo "$response" | grep -o '"content":"[^"]*"' | head -1 | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g')
        
        if [ -n "$reply" ]; then
            echo -e "${reply}"
            # 添加到历史
            history="${history}{\"role\":\"assistant\",\"content\":\"$(echo "$reply" | sed 's/"/\\"/g')\"},"
        else
            echo -e "${RED}[错误] 无法获取回复${NC}"
        fi
        
        echo ""
    done
}

# 代码生成模式
code_mode() {
    local task="$1"
    echo -e "\n${CYAN}━━━ 代码生成 ━━━${NC}\n"
    
    local response=$(curl -s -X POST "${MIMO_API}/v1/chat/completions" \\
            -H "Authorization: Bearer $MIMO_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"messages\": [
                {\"role\": \"system\", \"content\": \"你是 MiMo，擅长编程的 AI 助手。请直接输出代码，使用 markdown 代码块格式。\"},
                {\"role\": \"user\", \"content\": \"${task}\"}
            ],
            \"max_tokens\": 4096,
            \"temperature\": 0.3
        }")
    
    echo "$response" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' | sed 's/\\n/\n/g'
    echo ""
}

# 使用帮助
usage() {
    echo -e "${BOLD}MiMo v2.5 Pro Chat CLI${NC}"
    echo ""
    echo "用法:"
    echo "  mimo_chat.sh                    交互式对话模式"
    echo "  mimo_chat.sh ask \"问题\"          单次提问"
    echo "  mimo_chat.sh code \"编程任务\"     代码生成模式"
    echo "  mimo_chat.sh status             检查服务状态"
    echo ""
    echo "示例:"
    echo "  mimo_chat.sh ask \"什么是量子计算？\""
    echo "  mimo_chat.sh code \"写一个 Python 快排算法\""
    echo ""
}

# 主入口
case "${1}" in
    ask|-a|--ask)
        check_service
        ask_mode "$2"
        ;;
    code|-c|--code)
        check_service
        code_mode "$2"
        ;;
    status|-s|--status)
        check_service
        echo -e "  模型: ${BOLD}MiMo v2.5 Pro${NC}"
        echo -e "  API:  ${MIMO_API}"
        ;;
    help|-h|--help)
        usage
        ;;
    "")
        check_service
        interactive_mode
        ;;
    *)
        # 如果有参数但不是命令，当作单次提问
        check_service
        ask_mode "$*"
        ;;
esac
