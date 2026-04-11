#!/bin/bash

# OpenWRT 一键部署脚本
# 最简单的配置方式！

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   OpenWRT 一键部署工具                 ║${NC}"
echo -e "${CYAN}║   3 分钟完成配置                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# 检查是否已有配置
if [ -f "Config/CUSTOM.txt" ]; then
    echo -e "${YELLOW}⚠️  发现已有配置:${NC}"
    echo ""
    echo "  文件：Config/CUSTOM.txt"
    echo "  修改时间：$(stat -c %y Config/CUSTOM.txt | cut -d'.' -f1)"
    echo ""
    echo "是否使用现有配置？"
    echo ""
    echo "  [1] 是，直接使用现有配置"
    echo "  [2] 否，重新配置"
    echo ""
    PS3="${GREEN}请选择 (1-2): ${NC}"
    select choice in 1 2; do
        case $choice in
            1)
                echo -e "${GREEN}✓ 使用现有配置${NC}"
                echo ""
                echo -e "${CYAN}下一步:${NC}"
                echo "1. 提交配置：git add -A && git commit -m 'update config' && git push"
                echo "2. 开始编译：https://github.com/liuziqiang78-liu/OpenWRT-CI/actions"
                exit 0 ;;
            2)
                echo -e "${YELLOW}✓ 将重新配置${NC}"
                break ;;
        esac
    done
    echo ""
fi

# 运行配置向导
echo -e "${CYAN}启动配置向导...${NC}"
echo ""
bash Scripts/config-wizard.sh

# 如果向导没有自动复制，手动复制
if [ ! -f "Config/CUSTOM.txt" ]; then
    GENERATED_FILE=$(ls -t Config/generated/*.txt 2>/dev/null | head -1)
    if [ -n "$GENERATED_FILE" ]; then
        cp "$GENERATED_FILE" Config/CUSTOM.txt
        echo -e "${GREEN}✓ 已复制到 Config/CUSTOM.txt${NC}"
    fi
fi

echo ""
