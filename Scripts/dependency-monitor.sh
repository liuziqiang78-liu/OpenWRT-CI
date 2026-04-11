#!/bin/bash

# OpenWRT-CI 依赖仓库监控脚本
# 检查所有外部 GitHub 依赖仓库的状态

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 输出目录
OUTPUT_DIR="./dependency-monitor"
mkdir -p "$OUTPUT_DIR"

# 依赖仓库列表 (从 Packages.sh 提取)
declare -A REPOS=(
    # 主题类
    ["argon"]="sbwml/luci-theme-argon:openwrt-25.12"
    ["aurora"]="eamonxg/luci-theme-aurora:master"
    ["aurora-config"]="eamonxg/luci-app-aurora-config:master"
    ["kucat"]="sirpdboy/luci-theme-kucat:master"
    ["kucat-config"]="sirpdboy/luci-app-kucat-config:master"
    
    # 代理类
    ["homeproxy"]="VIKINGYFY/homeproxy:main"
    ["momo"]="nikkinikki-org/OpenWrt-momo:main"
    ["nikki"]="nikkinikki-org/OpenWrt-nikki:main"
    ["openclash"]="vernesong/OpenClash:dev"
    ["passwall"]="Openwrt-Passwall/openwrt-passwall:main"
    ["passwall2"]="Openwrt-Passwall/openwrt-passwall2:main"
    
    # 网络工具
    ["tailscale"]="Tokisaki-Galaxy/luci-app-tailscale-community:master"
    ["ddns-go"]="sirpdboy/luci-app-ddns-go:main"
    ["easytier"]="EasyTier/luci-app-easytier:main"
    ["vnt"]="lmq8267/luci-app-vnt:main"
    
    # 存储工具
    ["diskman"]="lisaac/luci-app-diskman:master"
    ["qbittorrent"]="sbwml/luci-app-qbittorrent:master"
    ["openlist2"]="sbwml/luci-app-openlist2:main"
    ["quickfile"]="sbwml/luci-app-quickfile:main"
    
    # 系统工具
    ["fancontrol"]="rockjake/luci-app-fancontrol:main"
    ["mosdns"]="sbwml/luci-app-mosdns:v5"
    ["netspeedtest"]="sirpdboy/luci-app-netspeedtest:main"
    ["partexp"]="sirpdboy/luci-app-partexp:main"
    ["qmodem"]="FUjr/QModem:main"
    ["viking"]="VIKINGYFY/packages:main"
    ["lucky"]="sirpdboy/luci-app-lucky:main"
    ["gecoosac"]="laipeng668/luci-app-gecoosac:main"
    
    # 源码仓库
    ["immortalwrt-official"]="immortalwrt/immortalwrt:owrt"
    ["immortalwrt-viking"]="VIKINGYFY/immortalwrt:owrt"
    ["uboot-emmc"]="chenxin527/uboot-ipq60xx-emmc-build:main"
    ["uboot-nand"]="chenxin527/uboot-ipq60xx-nand-build:main"
    ["uboot-nor"]="chenxin527/uboot-ipq60xx-nor-build:main"
)

# 统计
TOTAL=0
HEALTHY=0
WARNING=0
CRITICAL=0

# 检查单个仓库
check_repo() {
    local NAME=$1
    local REPO_INFO=$2
    local REPO=${REPO_INFO%%:*}
    local BRANCH=${REPO_INFO##*:}
    
    TOTAL=$((TOTAL + 1))
    
    echo -e "${BLUE}Checking: ${NAME} (${REPO}@${BRANCH})${NC}"
    
    # 调用 GitHub API
    local API_URL="https://api.github.com/repos/${REPO}"
    local RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL" 2>/dev/null || echo "000")
    local HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    local BODY=$(echo "$RESPONSE" | sed '$d')
    
    local STATUS="UNKNOWN"
    local LAST_COMMIT="N/A"
    local STARGAZERS="N/A"
    local FORKS="N/A"
    local ARCHIVED="false"
    
    if [ "$HTTP_CODE" = "200" ]; then
        ARCHIVED=$(echo "$BODY" | jq -r '.archived // false')
        STARGAZERS=$(echo "$BODY" | jq -r '.stargazers_count // 0')
        FORKS=$(echo "$BODY" | jq -r '.forks_count // 0')
        
        # 检查分支
        local BRANCH_URL="https://api.github.com/repos/${REPO}/branches/${BRANCH}"
        local BRANCH_RESPONSE=$(curl -s -w "\n%{http_code}" "$BRANCH_URL" 2>/dev/null || echo "000")
        local BRANCH_CODE=$(echo "$BRANCH_RESPONSE" | tail -n1)
        local BRANCH_BODY=$(echo "$BRANCH_RESPONSE" | sed '$d')
        
        if [ "$BRANCH_CODE" = "200" ]; then
            LAST_COMMIT=$(echo "$BRANCH_BODY" | jq -r '.commit.commit.author.date // "N/A"')
            
            # 检查最后提交时间
            local COMMIT_DATE=$(echo "$LAST_COMMIT" | cut -d'T' -f1)
            local DAYS_AGO=$(( ($(date +%s) - $(date -d "$COMMIT_DATE" +%s 2>/dev/null || echo 0)) / 86400 ))
            
            if [ "$ARCHIVED" = "true" ]; then
                STATUS="⚠️  ARCHIVED"
                WARNING=$((WARNING + 1))
            elif [ $DAYS_AGO -gt 365 ]; then
                STATUS="⚠️  STALE (${DAYS_AGO} days)"
                WARNING=$((WARNING + 1))
            elif [ $DAYS_AGO -gt 180 ]; then
                STATUS="⚠️  OLD (${DAYS_AGO} days)"
                WARNING=$((WARNING + 1))
            else
                STATUS="✅ HEALTHY"
                HEALTHY=$((HEALTHY + 1))
            fi
        else
            STATUS="❌ BRANCH NOT FOUND"
            CRITICAL=$((CRITICAL + 1))
        fi
    elif [ "$HTTP_CODE" = "404" ]; then
        STATUS="❌ NOT FOUND"
        CRITICAL=$((CRITICAL + 1))
    elif [ "$HTTP_CODE" = "403" ]; then
        STATUS="⚠️  RATE LIMITED"
        WARNING=$((WARNING + 1))
    else
        STATUS="❌ API ERROR (${HTTP_CODE})"
        CRITICAL=$((CRITICAL + 1))
    fi
    
    # 输出结果
    printf "%-20s | %-30s | %-15s | ⭐ %-6s | 🍴 %-6s | %s\n" \
        "$NAME" "$REPO@$BRANCH" "$STATUS" "$STARGAZERS" "$FORKS" "$LAST_COMMIT"
    
    # 保存到文件
    echo "${NAME}|${REPO}|${BRANCH}|${STATUS}|${STARGAZERS}|${FORKS}|${LAST_COMMIT}" >> "$OUTPUT_DIR/results.csv"
}

# 主函数
main() {
    echo "========================================"
    echo "  OpenWRT-CI 依赖仓库健康检查"
    echo "  检查时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""
    
    # CSV 头部
    echo "NAME|REPO|BRANCH|STATUS|STARS|FORKS|LAST_COMMIT" > "$OUTPUT_DIR/results.csv"
    
    # 表头
    printf "%-20s | %-30s | %-15s | %-8s | %-8s | %s\n" \
        "名称" "仓库@分支" "状态" "Stars" "Forks" "最后提交"
    echo "----------------------------------------------------------------------------------------------------"
    
    # 检查所有仓库
    for NAME in "${!REPOS[@]}"; do
        check_repo "$NAME" "${REPOS[$NAME]}"
        sleep 1  # 避免 API 限流
    done
    
    # 统计摘要
    echo ""
    echo "========================================"
    echo "  统计摘要"
    echo "========================================"
    echo -e "  总仓库数：${TOTAL}"
    echo -e "  ${GREEN}健康：${HEALTHY}${NC}"
    echo -e "  ${YELLOW}警告：${WARNING}${NC}"
    echo -e "  ${RED}严重：${CRITICAL}${NC}"
    echo ""
    
    # 生成 Markdown 报告
    cat > "$OUTPUT_DIR/report.md" << EOF
# OpenWRT-CI 依赖仓库健康检查报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')

## 统计摘要

| 指标 | 数量 |
|------|------|
| 总仓库数 | ${TOTAL} |
| 健康 | ${HEALTHY} |
| 警告 | ${WARNING} |
| 严重 | ${CRITICAL} |

## 详细列表

| 名称 | 仓库 | 分支 | 状态 | Stars | Forks | 最后提交 |
|------|------|------|------|-------|-------|----------|
EOF
    
    tail -n +2 "$OUTPUT_DIR/results.csv" | while IFS='|' read -r NAME REPO BRANCH STATUS STARS FORKS LAST_COMMIT; do
        echo "| ${NAME} | ${REPO} | ${BRANCH} | ${STATUS} | ${STARS} | ${FORKS} | ${LAST_COMMIT} |" >> "$OUTPUT_DIR/report.md"
    done
    
    echo "" >> "$OUTPUT_DIR/report.md"
    echo "---" >> "$OUTPUT_DIR/report.md"
    echo "*报告由 dependency-monitor.sh 自动生成*" >> "$OUTPUT_DIR/report.md"
    
    echo "报告已保存到：$OUTPUT_DIR/report.md"
}

# 执行
main
