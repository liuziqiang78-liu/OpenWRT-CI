#!/system/bin/sh
# MiMo Tool: File Operations
# 用法: file_ops.sh <action> <path> [args...]

ACTION="$1"
PATH_ARG="$2"
shift 2
ARGS="$*"

case "$ACTION" in
    read|cat)
        if [ ! -f "$PATH_ARG" ]; then
            echo "错误: 文件不存在: $PATH_ARG"
            exit 1
        fi
        echo "📄 文件: $PATH_ARG"
        echo "---"
        cat "$PATH_ARG"
        ;;
    write)
        if [ -z "$ARGS" ]; then
            echo "错误: 请提供内容"
            exit 1
        fi
        echo "$ARGS" > "$PATH_ARG"
        echo "✓ 已写入: $PATH_ARG"
        ;;
    edit)
        # ARGS 格式: "old_text|||new_text"
        OLD=$(echo "$ARGS" | cut -d'|' -f1-3 | sed 's/|||//')
        NEW=$(echo "$ARGS" | cut -d'|' -f4-)
        if grep -q "$OLD" "$PATH_ARG"; then
            sed -i "s|$OLD|$NEW|g" "$PATH_ARG"
            echo "✓ 已编辑: $PATH_ARG"
        else
            echo "错误: 未找到要替换的内容"
            exit 1
        fi
        ;;
    ls|list)
        if [ -d "$PATH_ARG" ]; then
            ls -la "$PATH_ARG"
        else
            echo "错误: 目录不存在: $PATH_ARG"
            exit 1
        fi
        ;;
    mkdir)
        mkdir -p "$PATH_ARG"
        echo "✓ 已创建目录: $PATH_ARG"
        ;;
    rm|delete)
        if [ -f "$PATH_ARG" ] || [ -d "$PATH_ARG" ]; then
            rm -rf "$PATH_ARG"
            echo "✓ 已删除: $PATH_ARG"
        else
            echo "错误: 不存在: $PATH_ARG"
            exit 1
        fi
        ;;
    cp|copy)
        cp -r "$PATH_ARG" "$ARGS"
        echo "✓ 已复制: $PATH_ARG -> $ARGS"
        ;;
    mv|move)
        mv "$PATH_ARG" "$ARGS"
        echo "✓ 已移动: $PATH_ARG -> $ARGS"
        ;;
    find)
        find "$PATH_ARG" -name "$ARGS" 2>/dev/null
        ;;
    head)
        head -n "${ARGS:-20}" "$PATH_ARG"
        ;;
    tail)
        tail -n "${ARGS:-20}" "$PATH_ARG"
        ;;
    wc)
        wc -l -w -c "$PATH_ARG"
        ;;
    grep)
        grep -rn "$ARGS" "$PATH_ARG" 2>/dev/null
        ;;
    *)
        echo "用法: file_ops.sh <action> <path> [args]"
        echo "Actions: read, write, edit, ls, mkdir, rm, cp, mv, find, head, tail, wc, grep"
        exit 1
        ;;
esac
