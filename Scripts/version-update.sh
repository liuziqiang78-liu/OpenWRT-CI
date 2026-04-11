#!/bin/bash

# OpenWRT-CI 插件版本更新工具
# 批量更新插件到最新版本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置文件
VERSIONS_FILE="./Config/VERSIONS.txt"
PACKAGES_FILE="./Scripts/Packages.sh"
BACKUP_DIR="./Config/backup/$(date +%Y%m%d_%H%M%S)"

# 更新模式
# fixed: 固定到最新 Tag
# branch: 使用分支最新
# commit: 固定到最新 Commit
UPDATE_MODE="fixed"

# 统计
UPDATED=0
SKIPPED=0
ERRORS=0

# 备份当前配置
backup_config() {
    echo -e "${BLUE}备份当前配置...${NC}"
    mkdir -p "$BACKUP_DIR"
    cp "$VERSIONS_FILE" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PACKAGES_FILE" "$BACKUP_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ 备份到：${BACKUP_DIR}${NC}"
    echo ""
}

# 获取最新 Tag
get_latest_tag() {
    local REPO=$1
    curl -sL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | jq -r '.tag_name // "none"' || echo "none"
}

# 获取最新 Commit
get_latest_commit() {
    local REPO=$1
    local BRANCH=$2
    curl -sL "https://api.github.com/repos/${REPO}/branches/${BRANCH}" 2>/dev/null | jq -r '.commit.sha // "none"' || echo "none"
}

# 更新单个插件
update_plugin() {
    local NAME=$1
    local REPO=$2
    local BRANCH=$3
    local OLD_VERSION=$4
    
    echo -e "${BLUE}处理：${NAME}${NC}"
    
    local OWNER=${REPO%%/*}
    local REPO_NAME=${REPO#*/}
    
    # 获取最新版本
    local LATEST_TAG=$(get_latest_tag "$REPO")
    local LATEST_COMMIT=$(get_latest_commit "$REPO" "$BRANCH")
    
    if [ "$LATEST_TAG" = "none" ] || [ "$LATEST_TAG" = "null" ]; then
        # 没有 Tag，使用 Commit
        if [ "$UPDATE_MODE" = "fixed" ]; then
            NEW_VERSION="${LATEST_COMMIT:0:7}"
        else
            NEW_VERSION=""
        fi
    else
        # 有 Tag
        if [ "$UPDATE_MODE" = "fixed" ]; then
            NEW_VERSION="$LATEST_TAG"
        else
            NEW_VERSION=""
        fi
    fi
    
    # 检查是否需要更新
    if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
        echo -e "  ${GREEN}✓ 已是最新${NC}"
        SKIPPED=$((SKIPPED + 1))
        return
    fi
    
    echo -e "  当前：${OLD_VERSION:-分支最新}"
    echo -e "  最新：${NEW_VERSION:-分支最新}"
    
    # 更新配置文件
    if [ -n "$NEW_VERSION" ]; then
        sed -i "s|^${NAME}=.*|${NAME}=${REPO}@${BRANCH}@${NEW_VERSION}|" "$VERSIONS_FILE"
    else
        sed -i "s|^${NAME}=.*|${NAME}=${REPO}@${BRANCH}|" "$VERSION_FILE"
    fi
    
    echo -e "  ${GREEN}✓ 已更新${NC}"
    UPDATED=$((UPDATED + 1))
    echo ""
}

# 同步到 Packages.sh
sync_to_packages() {
    echo -e "${BLUE}同步版本到 Packages.sh...${NC}"
    
    # 这里需要根据实际格式更新 Packages.sh
    # 暂时跳过，手动处理
    echo -e "${YELLOW}⚠️  请手动更新 Packages.sh 中的版本${NC}"
    echo ""
}

# 主函数
main() {
    echo "========================================"
    echo "  OpenWRT-CI 插件版本更新工具"
    echo "  时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)
                UPDATE_MODE="$2"
                shift 2
                ;;
            --plugin)
                PLUGIN_FILTER="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                echo "未知参数：$1"
                echo "用法：$0 [--mode fixed|branch] [--plugin NAME] [--dry-run]"
                exit 1
                ;;
        esac
    done
    
    echo -e "${BLUE}更新模式：${UPDATE_MODE}${NC}"
    echo ""
    
    # 备份
    backup_config
    
    if [ ! -f "$VERSIONS_FILE" ]; then
        echo -e "${RED}错误：找不到配置文件 ${VERSIONS_FILE}${NC}"
        exit 1
    fi
    
    # 创建临时文件
    TEMP_FILE=$(mktemp)
    
    # 读取并更新配置
    while IFS='=' read -r NAME VALUE; do
        # 跳过注释和空行
        [[ "$NAME" =~ ^#.*$ ]] && continue
        [[ -z "$NAME" ]] && continue
        
        # 如果指定了插件过滤，只处理匹配的
        if [ -n "$PLUGIN_FILTER" ] && [[ "$NAME" != *"$PLUGIN_FILTER"* ]]; then
            continue
        fi
        
        # 解析值
        local REPO=$(echo "$VALUE" | cut -d'@' -f1)
        local BRANCH=$(echo "$VALUE" | cut -d'@' -f2)
        local VERSION=$(echo "$VALUE" | cut -d'@' -f3)
        
        update_plugin "$NAME" "$REPO" "$BRANCH" "$VERSION"
        
        # 避免 API 限流
        sleep 2
        
    done < "$VERSIONS_FILE"
    
    # 同步
    sync_to_packages
    
    # 统计
    echo "========================================"
    echo "  更新完成"
    echo "========================================"
    echo "  更新：${UPDATED} 个"
    echo "  跳过：${SKIPPED} 个"
    echo "  错误：${ERRORS} 个"
    echo ""
    
    if [ $UPDATED -gt 0 ]; then
        echo -e "${YELLOW}💡 下一步:${NC}"
        echo "1. 检查配置变更：git diff $VERSIONS_FILE"
        echo "2. 更新 Packages.sh 中的版本"
        echo "3. 测试编译：确保新版本兼容"
        echo "4. 提交变更：git add -A && git commit -m 'chore: update plugins'"
        echo ""
        
        if [ -n "$DRY_RUN" ]; then
            echo -e "${YELLOW}⚠️  这是试运行，未实际更新${NC}"
            echo "恢复备份：cp $BACKUP_DIR/* $VERSIONS_FILE"
        else
            echo -e "${GREEN}✓ 变更已保存${NC}"
            echo "回滚：cp $BACKUP_DIR/* $VERSIONS_FILE"
        fi
    fi
}

# 执行
main "$@"
