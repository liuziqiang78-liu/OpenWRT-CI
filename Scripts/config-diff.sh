#!/bin/bash

# OpenWRT-CI 配置对比工具
# 对比两个配置文件的差异

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置目录
CONFIG_DIR="./Config"

# 显示用法
usage() {
    echo "用法：$0 <配置 1> <配置 2>"
    echo ""
    echo "示例:"
    echo "  $0 MEDIATEK ROCKCHIP"
    echo "  $0 IPQ60XX-WIFI-YES IPQ60XX-WIFI-NO"
    echo ""
    echo "可用的配置文件:"
    ls -1 "$CONFIG_DIR"/*.txt 2>/dev/null | xargs -n1 basename | sed 's/.txt$//' | while read f; do
        echo "  - $f"
    done
    exit 1
}

# 检查参数
if [ -z "$1" ] || [ -z "$2" ]; then
    usage
fi

CONFIG1="$1"
CONFIG2="$2"
FILE1="$CONFIG_DIR/${CONFIG1}.txt"
FILE2="$CONFIG_DIR/${CONFIG2}.txt"

# 检查文件是否存在
if [ ! -f "$FILE1" ]; then
    echo -e "${RED}错误：找不到配置文件 $FILE1${NC}"
    exit 1
fi

if [ ! -f "$FILE2" ]; then
    echo -e "${RED}错误：找不到配置文件 $FILE2${NC}"
    exit 1
fi

# 对比配置
echo "========================================"
echo "  OpenWRT-CI 配置对比"
echo "========================================"
echo ""
echo -e "${BLUE}配置 1:${NC} $CONFIG1"
echo -e "${BLUE}配置 2:${NC} $CONFIG2"
echo ""

# 提取设备列表
echo -e "${YELLOW}=== 设备差异 ===${NC}"
echo ""

DEVICES1=$(grep "CONFIG_TARGET_DEVICE_" "$FILE1" | grep "=y" | sed 's/CONFIG_TARGET_DEVICE_//' | sed 's/=y//' | sort)
DEVICES2=$(grep "CONFIG_TARGET_DEVICE_" "$FILE2" | grep "=y" | sed 's/CONFIG_TARGET_DEVICE_//' | sed 's/=y//' | sort)

# 只在配置 1 中的设备
echo -e "${GREEN}✓ 仅在 $CONFIG1 中:${NC}"
comm -23 <(echo "$DEVICES1") <(echo "$DEVICES2") | sed 's/^/  /'
echo ""

# 只在配置 2 中的设备
echo -e "${RED}✗ 仅在 $CONFIG2 中:${NC}"
comm -13 <(echo "$DEVICES1") <(echo "$DEVICES2") | sed 's/^/  /'
echo ""

# 共同设备
echo -e "${BLUE}= 共同支持:${NC}"
comm -12 <(echo "$DEVICES1") <(echo "$DEVICES2") | wc -l | xargs echo "  设备数:"
echo ""

# 对比插件配置
echo -e "${YELLOW}=== 插件差异 ===${NC}"
echo ""

PLUGINS1=$(grep "CONFIG_PACKAGE_" "$FILE1" | grep "=y" | sort)
PLUGINS2=$(grep "CONFIG_PACKAGE_" "$FILE2" | grep "=y" | sort)

echo -e "${GREEN}✓ 仅在 $CONFIG1 中:${NC}"
diff <(echo "$PLUGINS1") <(echo "$PLUGINS2") | grep "^<" | sed 's/^< CONFIG_PACKAGE_//' | sed 's/^/  /' || true
echo ""

echo -e "${RED}✗ 仅在 $CONFIG2 中:${NC}"
diff <(echo "$PLUGINS1") <(echo "$PLUGINS2") | grep "^>" | sed 's/^> CONFIG_PACKAGE_//' | sed 's/^/  /' || true
echo ""

# 统计
echo "========================================"
echo "  统计"
echo "========================================"
echo ""

TOTAL1=$(grep "=y" "$FILE1" | wc -l)
TOTAL2=$(grep "=y" "$FILE2" | wc -l)

echo "  $CONFIG1: $TOTAL1 个配置项"
echo "  $CONFIG2: $TOTAL2 个配置项"
echo ""

# 生成摘要文件
SUMMARY_FILE="$CONFIG_DIR/compare_${CONFIG1}_vs_${CONFIG2}.txt"
{
    echo "# 配置对比：$CONFIG1 vs $CONFIG2"
    echo "# 生成时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "## 设备差异"
    echo ""
    echo "### 仅在 $CONFIG1 中"
    comm -23 <(echo "$DEVICES1") <(echo "$DEVICES2")
    echo ""
    echo "### 仅在 $CONFIG2 中"
    comm -13 <(echo "$DEVICES1") <(echo "$DEVICES2")
    echo ""
    echo "## 插件差异"
    echo ""
    echo "### 仅在 $CONFIG1 中"
    diff <(echo "$PLUGINS1") <(echo "$PLUGINS2") | grep "^<" | sed 's/^< //' || true
    echo ""
    echo "### 仅在 $CONFIG2 中"
    diff <(echo "$PLUGINS1") <(echo "$PLUGINS2") | grep "^>" | sed 's/^> //' || true
} > "$SUMMARY_FILE"

echo -e "${GREEN}✓ 对比报告已保存到：$SUMMARY_FILE${NC}"
