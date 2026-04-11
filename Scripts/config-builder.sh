#!/bin/bash

# OpenWRT-CI 配置组合工具
# 将模块化配置合并为完整配置文件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置目录
CONFIG_DIR="./Config"
OUTPUT_DIR="./Config/generated"

# 显示用法
usage() {
    echo "用法：$0 <平台> <设备> [模板...]"
    echo ""
    echo "平台：MEDIATEK | ROCKCHIP | X86 | QUALCOMMAX"
    echo "设备：设备配置文件名 (不含 .txt)"
    echo "模板：可选的模板名称 (basic/gaming/full/custom)"
    echo ""
    echo "示例:"
    echo "  $0 MEDIATEK xiaomi_ax3000t full"
    echo "  $0 ROCKCHIP nanopi_r4s basic proxy"
    echo "  $0 X86 generic storage adblock"
    exit 1
}

# 检查参数
if [ $# -lt 2 ]; then
    usage
fi

PLATFORM=$1
DEVICE=$2
shift 2
TEMPLATES=("$@")

# 默认模板
if [ ${#TEMPLATES[@]} -eq 0 ]; then
    TEMPLATES=("basic")
fi

echo -e "${BLUE}=== OpenWRT 配置组合工具 ===${NC}"
echo ""
echo -e "平台：${YELLOW}${PLATFORM}${NC}"
echo -e "设备：${YELLOW}${DEVICE}${NC}"
echo -e "模板：${YELLOW}${TEMPLATES[*]}${NC}"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 输出文件
OUTPUT_FILE="$OUTPUT_DIR/${PLATFORM}_${DEVICE}_$(date +%Y%m%d_%H%M%S).txt"

# 开始组合
echo -e "${BLUE}开始组合配置...${NC}"
echo ""

# 写入文件头
cat > "$OUTPUT_FILE" << EOF
# OpenWRT 配置文件
# 生成时间：$(date '+%Y-%m-%d %H:%M:%S')
# 平台：$PLATFORM
# 设备：$DEVICE
# 模板：${TEMPLATES[*]}

# ============ 平台配置 ============
EOF

# 添加平台配置
PLATFORM_FILE="$CONFIG_DIR/platform/${PLATFORM}.txt"
if [ -f "$PLATFORM_FILE" ]; then
    echo -e "${GREEN}✓ 添加平台配置：${PLATFORM}${NC}"
    cat "$PLATFORM_FILE" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
else
    echo -e "${RED}✗ 平台配置不存在：${PLATFORM_FILE}${NC}"
    exit 1
fi

# 添加设备配置
DEVICE_FILE="$CONFIG_DIR/device/${DEVICE}.txt"
if [ -f "$DEVICE_FILE" ]; then
    echo -e "${GREEN}✓ 添加设备配置：${DEVICE}${NC}"
    cat "$DEVICE_FILE" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
else
    echo -e "${YELLOW}⚠ 设备配置不存在：${DEVICE_FILE}${NC}"
fi

# 添加基础配置 (始终包含)
for base in network wifi packages; do
    BASE_FILE="$CONFIG_DIR/base/${base}.txt"
    if [ -f "$BASE_FILE" ]; then
        echo -e "${GREEN}✓ 添加基础配置：${base}${NC}"
        cat "$BASE_FILE" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# 添加模板配置
for template in "${TEMPLATES[@]}"; do
    case $template in
        basic)
            # basic 已包含
            ;;
        proxy)
            PROXY_FILE="$CONFIG_DIR/base/proxy.txt"
            if [ -f "$PROXY_FILE" ]; then
                echo -e "${GREEN}✓ 添加模板：proxy${NC}"
                cat "$PROXY_FILE" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            fi
            ;;
        adblock)
            ADBLOCK_FILE="$CONFIG_DIR/base/adblock.txt"
            if [ -f "$ADBLOCK_FILE" ]; then
                echo -e "${GREEN}✓ 添加模板：adblock${NC}"
                cat "$ADBLOCK_FILE" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            fi
            ;;
        storage)
            STORAGE_FILE="$CONFIG_DIR/base/storage.txt"
            if [ -f "$STORAGE_FILE" ]; then
                echo -e "${GREEN}✓ 添加模板：storage${NC}"
                cat "$STORAGE_FILE" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            fi
            ;;
        network-extra)
            EXTRA_FILE="$CONFIG_DIR/base/network-extra.txt"
            if [ -f "$EXTRA_FILE" ]; then
                echo -e "${GREEN}✓ 添加模板：network-extra${NC}"
                cat "$EXTRA_FILE" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            fi
            ;;
        theme)
            THEME_FILE="$CONFIG_DIR/base/theme.txt"
            if [ -f "$THEME_FILE" ]; then
                echo -e "${GREEN}✓ 添加模板：theme${NC}"
                cat "$THEME_FILE" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            fi
            ;;
        full)
            # full 包含所有模板
            for extra in proxy storage network-extra theme; do
                EXTRA_FILE="$CONFIG_DIR/base/${extra}.txt"
                if [ -f "$EXTRA_FILE" ]; then
                    echo -e "${GREEN}✓ 添加模板：${extra}${NC}"
                    cat "$EXTRA_FILE" >> "$OUTPUT_FILE"
                    echo "" >> "$OUTPUT_FILE"
                fi
            done
            ;;
        custom)
            CUSTOM_FILE="$CONFIG_DIR/base/custom.txt"
            if [ -f "$CUSTOM_FILE" ]; then
                echo -e "${GREEN}✓ 添加模板：custom${NC}"
                cat "$CUSTOM_FILE" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            fi
            ;;
        *)
            echo -e "${YELLOW}⚠ 未知模板：${template}${NC}"
            ;;
    esac
done

# 添加通用配置
echo "# ============ 通用配置 ============" >> "$OUTPUT_FILE"
cat "$CONFIG_DIR/GENERAL.txt" >> "$OUTPUT_FILE"

echo ""
echo -e "${GREEN}✓ 配置生成完成！${NC}"
echo ""
echo -e "输出文件：${BLUE}${OUTPUT_FILE}${NC}"
echo ""
echo "下一步:"
echo "1. 检查配置：cat $OUTPUT_FILE"
echo "2. 复制到 Config 目录：cp $OUTPUT_FILE Config/CUSTOM.txt"
echo "3. 手动编译：Actions → WRT-TEST → Run workflow"
echo ""
