#!/system/bin/sh
# MiMo Tool: Code Executor
# 用法: code_exec.sh <language> <code>
# 支持: python, node, shell, lua, ruby

LANG="$1"
shift
CODE="$*"
TMP_DIR="/data/adb/mimo/tmp"
mkdir -p "$TMP_DIR"

execute_python() {
    if command -v python3 > /dev/null 2>&1; then
        echo "$CODE" | python3 2>&1
    elif command -v python > /dev/null 2>&1; then
        echo "$CODE" | python 2>&1
    else
        echo "错误: Python 未安装"
        echo "安装: pkg install python"
        return 1
    fi
}

execute_node() {
    if command -v node > /dev/null 2>&1; then
        echo "$CODE" | node 2>&1
    else
        echo "错误: Node.js 未安装"
        echo "安装: pkg install nodejs"
        return 1
    fi
}

execute_shell() {
    echo "$CODE" | sh 2>&1
}

execute_lua() {
    if command -v lua > /dev/null 2>&1; then
        echo "$CODE" | lua 2>&1
    else
        echo "错误: Lua 未安装"
        return 1
    fi
}

execute_ruby() {
    if command -v ruby > /dev/null 2>&1; then
        echo "$CODE" | ruby 2>&1
    else
        echo "错误: Ruby 未安装"
        return 1
    fi
}

# 路由到对应解释器
case "$LANG" in
    python|py|python3)
        echo "🐍 Python 执行:"
        execute_python
        ;;
    node|nodejs|js|javascript)
        echo "📦 Node.js 执行:"
        execute_node
        ;;
    shell|sh|bash)
        echo "🐚 Shell 执行:"
        execute_shell
        ;;
    lua)
        echo "🌙 Lua 执行:"
        execute_lua
        ;;
    ruby|rb)
        echo "💎 Ruby 执行:"
        execute_ruby
        ;;
    *)
        echo "❌ 不支持的语言: $LANG"
        echo "支持: python, node, shell, lua, ruby"
        exit 1
        ;;
esac
