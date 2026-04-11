#!/bin/bash

# OpenWRT-CI 插件版本检查工具
# 检查所有插件是否有新版本可用

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置文件
VERSIONS_FILE="./Config/VERSIONS.txt"

# 统计
TOTAL=0
UPDATE_AVAILABLE=0
LATEST=0
ERRORS=0

# 检查单个插件
check_plugin() {
    local NAME=$1
    local REPO=$2
    local BRANCH=$3
    local FIXED_VERSION=$4
    
    TOTAL=$((TOTAL + 1))
    
    # 解析仓库所有者
    local OWNER=${REPO%%/*}
    local REPO_NAME=${REPO#*/}
    
    echo -e "${BLUE}Checking: ${NAME}${NC} (${REPO}@${BRANCH})"
    
    # 如果有固定版本，检查是否为最新
    if [ -n "$FIXED_VERSION" ]; then
        # 获取最新 Tag
        local LATEST_TAG=$(curl -sL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | jq -r '.tag_name // "none"' || echo "none")
        
        if [ "$LATEST_TAG" = "none" ] || [ "$LATEST_TAG" = "null" ]; then
            # 没有 releases，检查分支最新 commit
            local BRANCH_INFO=$(curl -sL "https://api.github.com/repos/${REPO}/branches/${BRANCH}" 2>/dev/null || echo "{}")
            local COMMIT_HASH=$(echo "$BRANCH_INFO" | jq -r '.commit.sha // "unknown"' || echo "unknown")
            
            if [ "$COMMIT_HASH" = "unknown" ]; then
                echo -e "  ${YELLOW}⚠️  无法获取版本信息${NC}"
                ERRORS=$((ERRORS + 1))
                return
            fi
            
            echo -e "  当前：${FIXED_VERSION}"
            echo -e "  最新 Commit: ${COMMIT_HASH:0:7}"
            
            if [ "$FIXED_VERSION" = "${COMMIT_HASH:0:7}" ] || [ "$FIXED_VERSION" = "$COMMIT_HASH" ]; then
                echo -e "  ${GREEN}✅ 已是最新${NC}"
                LATEST=$((LATEST + 1))
            else
                echo -e "  ${YELLOW}⚠️  有新 Commit (未使用 Tag 锁定)${NC}"
                UPDATE_AVAILABLE=$((UPDATE_AVAILABLE + 1))
            fi
        else
            echo -e "  当前：${FIXED_VERSION}"
            echo -e "  最新：${LATEST_TAG}"
            
            if [ "$FIXED_VERSION" = "$LATEST_TAG" ]; then
                echo -e "  ${GREEN}✅ 已是最新${NC}"
                LATEST=$((LATEST + 1))
            else
                echo -e "  ${GREEN}📦 有新版本：${LATEST_TAG}${NC}"
                UPDATE_AVAILABLE=$((UPDATE_AVAILABLE + 1))
            fi
        fi
    else
        # 没有固定版本，检查分支最后更新时间
        local BRANCH_INFO=$(curl -sL "https://api.github.com/repos/${REPO}/branches/${BRANCH}" 2>/dev/null || echo "{}")
        local COMMIT_DATE=$(echo "$BRANCH_INFO" | jq -r '.commit.commit.author.date // "unknown"' || echo "unknown")
        local COMMIT_SHA=$(echo "$BRANCH_INFO" | jq -r '.commit.sha // "unknown"' || echo "unknown")
        
        if [ "$COMMIT_DATE" = "unknown" ]; then
            echo -e "  ${YELLOW}⚠️  无法获取分支信息${NC}"
            ERRORS=$((ERRORS + 1))
            return
        fi
        
        # 计算多少天前
        local COMMIT_TIMESTAMP=$(date -d "$COMMIT_DATE" +%s 2>/dev/null || echo 0)
        local NOW_TIMESTAMP=$(date +%s)
        local DAYS_AGO=$(( (NOW_TIMESTAMP - COMMIT_TIMESTAMP) / 86400 ))
        
        echo -e "  分支：${BRANCH}"
        echo -e "  最新 Commit: ${COMMIT_SHA:0:7}"
        echo -e "  最后更新：${COMMIT_DATE} (${DAYS_AGO}天前)"
        
        if [ $DAYS_AGO -gt 180 ]; then
            echo -e "  ${YELLOW}⚠️  分支已超过${DAYS_AGO}天未更新${NC}"
        else
            echo -e "  ${GREEN}✅ 活跃${NC}"
        fi
        
        LATEST=$((LATEST + 1))
    fi
    
    echo ""
}

# 主函数
main() {
    echo "========================================"
    echo "  OpenWRT-CI 插件版本检查"
    echo "  检查时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""
    
    if [ ! -f "$VERSIONS_FILE" ]; then
        echo -e "${RED}错误：找不到配置文件 ${VERSIONS_FILE}${NC}"
        exit 1
    fi
    
    # 读取配置文件
    while IFS='=' read -r NAME VALUE; do
        # 跳过注释和空行
        [[ "$NAME" =~ ^#.*$ ]] && continue
        [[ -z "$NAME" ]] && continue
        
        # 解析值：REPO@BRANCH@VERSION
        local REPO=$(echo "$VALUE" | cut -d'@' -f1)
        local BRANCH=$(echo "$VALUE" | cut -d'@' -f2)
        local VERSION=$(echo "$VALUE" | cut -d'@' -f3)
        
        check_plugin "$NAME" "$REPO" "$BRANCH" "$VERSION"
        
        # 避免 API 限流
        sleep 1
        
    done < "$VERSIONS_FILE"
    
    # 统计
    echo "========================================"
    echo "  统计摘要"
    echo "========================================"
    echo "  总插件数：${TOTAL}"
    echo -e "  ${GREEN}最新/活跃：${LATEST}${NC}"
    echo -e "  ${YELLOW}可更新：${UPDATE_AVAILABLE}${NC}"
    echo -e "  ${RED}错误：${ERRORS}${NC}"
    echo ""
    
    if [ $UPDATE_AVAILABLE -gt 0 ]; then
        echo -e "${YELLOW}💡 提示：有 ${UPDATE_AVAILABLE} 个插件可以更新${NC}"
        echo "运行以下命令查看详细信息:"
        echo "  bash Scripts/version-check.sh --verbose"
    fi
}

# 执行
main "$@"
