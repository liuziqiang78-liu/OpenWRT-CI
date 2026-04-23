#!/system/bin/sh
# MiMo Tool: GitHub
# 用法: github.sh <action> [args...]

ACTION="$1"
shift
ARGS="$*"

# 检查 gh CLI
if ! command -v gh > /dev/null 2>&1; then
    echo "错误: GitHub CLI 未安装"
    echo "安装: pkg install gh"
    exit 1
fi

case "$ACTION" in
    issue)
        gh issue $ARGS
        ;;
    pr)
        gh pr $ARGS
        ;;
    run)
        gh run $ARGS
        ;;
    api)
        gh api $ARGS
        ;;
    repo)
        gh repo $ARGS
        ;;
    search)
        gh search repos "$ARGS"
        ;;
    clone)
        gh repo clone "$ARGS"
        ;;
    *)
        echo "用法: github.sh <action> [args]"
        echo "Actions: issue, pr, run, api, repo, search, clone"
        exit 1
        ;;
esac
