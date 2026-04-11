#!/bin/bash

# OpenWRT 配置预览工具
# 快速查看配置信息

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE="${1:-Config/CUSTOM.txt}"

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   OpenWRT 配置预览                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# 检查文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ 配置文件不存在：${CONFIG_FILE}${NC}"
    exit 1
fi

echo -e "${BLUE}配置文件:${NC} $CONFIG_FILE"
echo -e "${BLUE}最后修改:${NC} $(stat -c %y "$CONFIG_FILE" | cut -d'.' -f1)"
echo ""

# 平台信息
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}平台信息${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

PLATFORM=$(grep "CONFIG_TARGET=" "$CONFIG_FILE" | head -1 | cut -d'=' -f2)
echo "  平台：${PLATFORM:-未知}"

DEVICE=$(grep "CONFIG_TARGET_DEVICE" "$CONFIG_FILE" | head -1 | sed 's/.*DEVICE_//' | sed 's/=y.*//')
echo "  设备：${DEVICE:-未知}"
echo ""

# 插件统计
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}插件统计${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

TOTAL=$(grep -c "CONFIG_PACKAGE_" "$CONFIG_FILE" || echo 0)
ENABLED=$(grep -c "=y" "$CONFIG_FILE" || echo 0)
DISABLED=$(grep -c "=n" "$CONFIG_FILE" || echo 0)

echo "  总配置：${TOTAL} 个"
echo "  已启用：${ENABLED} 个"
echo "  已禁用：${DISABLED} 个"
echo "  预估大小：$((ENABLED * 200)) KB"
echo ""

# 分类统计
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}分类统计${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 科学插件
PROXY_COUNT=0
for proxy in "passwall" "openclash" "homeproxy" "ssr-plus" "vssr"; do
    COUNT=$(grep -c "CONFIG_PACKAGE.*${proxy}" "$CONFIG_FILE" || echo 0)
    PROXY_COUNT=$((PROXY_COUNT + COUNT))
done
echo -e "  🌐 科学插件：${PROXY_COUNT} 个"

# 存储插件
STORAGE_COUNT=0
for storage in "samba" "aria2" "diskman" "qbittorrent"; do
    COUNT=$(grep -c "CONFIG_PACKAGE.*${storage}" "$CONFIG_FILE" || echo 0)
    STORAGE_COUNT=$((STORAGE_COUNT + COUNT))
done
echo -e "  💾 存储插件：${STORAGE_COUNT} 个"

# 网络插件
NETWORK_COUNT=0
for network in "ddns" "tailscale" "upnp" "wol"; do
    COUNT=$(grep -c "CONFIG_PACKAGE.*${network}" "$CONFIG_FILE" || echo 0)
    NETWORK_COUNT=$((NETWORK_COUNT + COUNT))
done
echo -e "  🌐 网络插件：${NETWORK_COUNT} 个"

# 主题插件
THEME_COUNT=$(grep -c "CONFIG_PACKAGE_luci-theme" "$CONFIG_FILE" || echo 0)
echo -e "  🎨 主题插件：${THEME_COUNT} 个"

# 系统工具
SYSTEM_COUNT=$(grep -c "CONFIG_PACKAGE_luci-app-\(autoreboot\|cpufreq\|ttyd\)" "$CONFIG_FILE" || echo 0)
echo -e "  🔧 系统工具：${SYSTEM_COUNT} 个"

echo ""

# 主要插件列表
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}主要插件${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo "科学上网:"
grep "CONFIG_PACKAGE.*\(passwall\|openclash\|homeproxy\)" "$CONFIG_FILE" | grep "=y" | sed 's/CONFIG_PACKAGE_//' | sed 's/=y//' | while read pkg; do
    echo "  ✓ $pkg"
done

echo ""
echo "存储管理:"
grep "CONFIG_PACKAGE.*\(samba\|aria2\|diskman\|qbittorrent\)" "$CONFIG_FILE" | grep "=y" | sed 's/CONFIG_PACKAGE_//' | sed 's/=y//' | while read pkg; do
    echo "  ✓ $pkg"
done

echo ""
echo "网络工具:"
grep "CONFIG_PACKAGE.*\(ddns\|tailscale\|upnp\)" "$CONFIG_FILE" | grep "=y" | sed 's/CONFIG_PACKAGE_//' | sed 's/=y//' | while read pkg; do
    echo "  ✓ $pkg"
done

echo ""
echo "主题:"
grep "CONFIG_PACKAGE_luci-theme" "$CONFIG_FILE" | grep "=y" | sed 's/CONFIG_PACKAGE_//' | sed 's/=y//' | while read pkg; do
    echo "  ✓ $pkg"
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 建议
if [ $ENABLED -gt 100 ]; then
    echo -e "${YELLOW}⚠️  提示：启用的插件较多，固件可能较大${NC}"
fi

if [ $PROXY_COUNT -gt 2 ]; then
    echo -e "${YELLOW}⚠️  提示：启用了多个科学插件，建议选择 1 个${NC}"
fi

if [ $THEME_COUNT -gt 1 ]; then
    echo -e "${YELLOW}⚠️  提示：启用了多个主题，建议选择 1 个${NC}"
fi

echo ""
