#!/bin/bash

# OpenWRT 交互式配置向导
# 让配置变得超级简单！

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置目录
CONFIG_DIR="./Config"
OUTPUT_DIR="./Config/generated"

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   OpenWRT 配置向导                     ║${NC}"
echo -e "${CYAN}║   只需 3 步，生成你的专属配置            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# ==================== 步骤 1: 选择平台 ====================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}步骤 1/3: 选择你的设备平台${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "请选择你的设备平台:"
echo ""

platforms=(
    "MEDIATEK:小米/360/京东云/华硕 (联发科)"
    "ROCKCHIP:NanoPi/香橙派/友善 (瑞芯微)"
    "X86:PC/笔记本/虚拟机 (通用)"
    "QUALCOMMAX:红米/Linksys (高通)"
)

PS3="${GREEN}请输入选项编号 (1-4): ${NC}"
select platform_data in "${platforms[@]}"; do
    if [ -n "$platform_data" ]; then
        PLATFORM=$(echo "$platform_data" | cut -d':' -f1)
        echo -e "${GREEN}✓ 已选择：${PLATFORM}${NC}"
        break
    else
        echo -e "${RED}✗ 无效选择，请重新输入${NC}"
    fi
done

echo ""

# ==================== 步骤 2: 选择设备 ====================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}步骤 2/3: 选择你的设备型号${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 获取平台对应的设备列表
device_files=$(ls "$CONFIG_DIR/device/"*.txt 2>/dev/null | xargs -n1 basename | sed 's/.txt//')

if [ -z "$device_files" ]; then
    echo -e "${RED}✗ 没有找到设备配置文件${NC}"
    echo "请确保 Config/device/ 目录下有设备配置文件"
    exit 1
fi

echo "可用设备:"
echo ""

device_list=()
i=1
for device in $device_files; do
    # 美化设备名称
    device_pretty=$(echo "$device" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
    echo "  [$i] $device_pretty"
    device_list+=("$device")
    ((i++))
done

echo ""
PS3="${GREEN}请输入设备编号: ${NC}"
select device in "${device_list[@]}"; do
    if [ -n "$device" ]; then
        DEVICE="$device"
        echo -e "${GREEN}✓ 已选择：${DEVICE}${NC}"
        break
    else
        echo -e "${RED}✗ 无效选择，请重新输入${NC}"
    fi
done

echo ""

# ==================== 步骤 3: 选择功能 ====================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}步骤 3/3: 选择需要的功能${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "请选择你需要的功能 (单选):"
echo ""
echo "  [1] 🏠 基础功能 - 仅上网 + WiFi (适合新手)"
echo "  [2] 🌐 科学上网 - 基础 + 代理插件 (推荐)"
echo "  [3] 🛡️  广告过滤 - 基础 + AdGuard Home"
echo "  [4] 💾 存储管理 - 基础 + NAS 功能"
echo "  [5] 🎮 游戏优化 - 基础 + 低延迟优化"
echo "  [6] 🚀 全部功能 - 所有插件 (高级用户)"
echo ""

PS3="${GREEN}请输入选项编号 (1-6): ${NC}"
select func_num in 1 2 3 4 5 6; do
    case $func_num in
        1) TEMPLATE="basic"; FUNC_DESC="基础功能"; break ;;
        2) TEMPLATE="proxy"; FUNC_DESC="科学上网"; break ;;
        3) TEMPLATE="adblock"; FUNC_DESC="广告过滤"; break ;;
        4) TEMPLATE="nas"; FUNC_DESC="存储管理"; break ;;
        5) TEMPLATE="gaming"; FUNC_DESC="游戏优化"; break ;;
        6) TEMPLATE="full"; FUNC_DESC="全部功能"; break ;;
        *) echo -e "${RED}✗ 无效选择${NC}" ;;
    esac
done

echo -e "${GREEN}✓ 已选择：${FUNC_DESC}${NC}"
echo ""

# ==================== 生成配置 ====================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}正在生成配置...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 运行配置组合工具
bash Scripts/config-builder.sh "$PLATFORM" "$DEVICE" "$TEMPLATE"

# 找到生成的文件
GENERATED_FILE=$(ls -t "$OUTPUT_DIR"/${PLATFORM}_${DEVICE}_*.txt 2>/dev/null | head -1)

if [ -z "$GENERATED_FILE" ]; then
    echo -e "${RED}✗ 配置生成失败${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ 配置生成完成！                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}配置信息:${NC}"
echo "  平台：${PLATFORM}"
echo "  设备：${DEVICE}"
echo "  功能：${FUNC_DESC}"
echo "  文件：${GENERATED_FILE}"
echo ""

# 显示配置摘要
echo -e "${BLUE}配置摘要:${NC}"
echo "  插件数量：$(grep -c "CONFIG_PACKAGE_" "$GENERATED_FILE") 个"
echo "  预估大小：$(($(grep -c "=y" "$GENERATED_FILE") * 200)) KB"
echo ""

# 询问是否复制为 CUSTOM.txt
echo "是否复制为 Config/CUSTOM.txt 以便编译？"
PS3="${GREEN}请选择 (y/n): ${NC}"
select answer in "是，立即复制" "否，我再看看"; do
    case $REPLY in
        1)
            cp "$GENERATED_FILE" "$CONFIG_DIR/CUSTOM.txt"
            echo -e "${GREEN}✓ 已复制到 Config/CUSTOM.txt${NC}"
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CYAN}下一步操作:${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo "1️⃣  检查配置:"
            echo "   cat Config/CUSTOM.txt"
            echo ""
            echo "2️⃣  提交配置:"
            echo "   git add -A"
            echo "   git commit -m 'chore: update config'"
            echo "   git push"
            echo ""
            echo "3️⃣  开始编译:"
            echo "   访问：https://github.com/liuziqiang78-liu/OpenWRT-CI/actions"
            echo "   选择：WRT-TEST → Run workflow"
            echo "   配置：CUSTOM"
            echo ""
            break ;;
        2)
            echo -e "${YELLOW}⚠️  配置已保存到：${GENERATED_FILE}${NC}"
            echo "需要时手动复制到 Config/CUSTOM.txt"
            break ;;
    esac
done

echo ""
echo -e "${GREEN}感谢使用 OpenWRT 配置向导！${NC}"
echo ""
