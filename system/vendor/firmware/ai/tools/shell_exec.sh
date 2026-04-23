#!/system/bin/sh
# MiMo Tool: Shell Command Executor
# 用法: shell_exec.sh <command>
# 安全执行 shell 命令，带超时和输出限制

CMD="$*"
TIMEOUT=30
MAX_OUTPUT=10000

if [ -z "$CMD" ]; then
    echo "错误: 请提供命令"
    exit 1
fi

# 安全检查 - 禁止危险命令
DANGEROUS_CMDS="rm -rf /|mkfs|dd if=|wget.*|curl.*-o|chmod 777|>:(){ :|:&};:"
for dc in $DANGEROUS_CMDS; do
    if echo "$CMD" | grep -q "$dc"; then
        echo "🚫 安全拒绝: 命令被安全策略阻止"
        exit 1
    fi
done

# 执行命令
echo "💻 执行: $CMD"
echo "---"
OUTPUT=$(timeout "$TIMEOUT" sh -c "$CMD" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 124 ]; then
    echo "⏰ 命令超时 (${TIMEOUT}s)"
elif [ $EXIT_CODE -ne 0 ]; then
    echo "❌ 错误 (退出码: $EXIT_CODE)"
fi

# 限制输出长度
echo "$OUTPUT" | head -c "$MAX_OUTPUT"

if [ ${#OUTPUT} -gt "$MAX_OUTPUT" ]; then
    echo ""
    echo "... (输出被截断，共 ${#OUTPUT} 字符)"
fi
