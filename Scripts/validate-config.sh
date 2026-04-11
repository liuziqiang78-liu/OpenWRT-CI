#!/bin/bash

# OpenWRT 配置验证工具
# 编译前必做检查！

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   OpenWRT 配置验证工具                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

CONFIG_FILE="${1:-Config/CUSTOM.txt}"
ERRORS=0
WARNINGS=0

# 检查文件存在
echo -e "${YELLOW}[1/6] 检查配置文件...${NC}"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ 配置文件不存在：${CONFIG_FILE}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 配置文件存在${NC}"
echo ""

# 检查必要配置
echo -e "${YELLOW}[2/6] 检查必要配置...${NC}"

if ! grep -q "CONFIG_TARGET=" "$CONFIG_FILE"; then
    echo -e "${RED}✗ 缺少平台配置 (CONFIG_TARGET)${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ 平台配置正确${NC}"
fi

if ! grep -q "CONFIG_TARGET_DEVICE" "$CONFIG_FILE"; then
    echo -e "${RED}✗ 缺少设备配置 (CONFIG_TARGET_DEVICE)${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ 设备配置正确${NC}"
fi

if ! grep -q "CONFIG_PACKAGE_luci-base" "$CONFIG_FILE"; then
    echo -e "${YELLOW}⚠  缺少基础包 (luci-base)，可能导致 Web 界面不可用${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ 基础包配置正确${NC}"
fi

echo ""

# 检查配置冲突
echo -e "${YELLOW}[3/6] 检查配置冲突...${NC}"

# 检查主题冲突
THEME_COUNT=$(grep -c "CONFIG_PACKAGE_luci-theme-" "$CONFIG_FILE" | grep "=y" || echo 0)
if [ "$THEME_COUNT" -gt 2 ]; then
    echo -e "${YELLOW}⚠️  启用了多个主题，建议选择 1 个${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ 主题配置正常${NC}"
fi

# 检查代理插件冲突
PROXY_COUNT=0
for proxy in "passwall" "openclash" "homeproxy" "ssr-plus"; do
    if grep -q "CONFIG_PACKAGE_luci-app-${proxy}=y" "$CONFIG_FILE"; then
        ((PROXY_COUNT++))
    fi
done

if [ "$PROXY_COUNT" -gt 2 ]; then
    echo -e "${YELLOW}⚠️  启用了多个代理插件，可能导致冲突${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ 代理插件配置正常${NC}"
fi

echo ""

# 检查依赖关系
echo -e "${YELLOW}[4/6] 检查依赖关系...${NC}"

# DiskMan 依赖
if grep -q "CONFIG_PACKAGE_luci-app-diskman=y" "$CONFIG_FILE"; then
    if ! grep -q "CONFIG_PACKAGE_block-mount=y" "$CONFIG_FILE"; then
        echo -e "${YELLOW}⚠️  DiskMan 需要 block-mount${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓ DiskMan 依赖满足${NC}"
    fi
fi

# Docker 依赖
if grep -q "CONFIG_PACKAGE_luci-app-dockerman=y" "$CONFIG_FILE"; then
    if ! grep -q "CONFIG_PACKAGE_docker=y" "$CONFIG_FILE"; then
        echo -e "${YELLOW}⚠️  DockerMan 需要 docker${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓ DockerMan 依赖满足${NC}"
    fi
fi

# Samba 依赖
if grep -q "CONFIG_PACKAGE_luci-app-samba4=y" "$CONFIG_FILE"; then
    if ! grep -q "CONFIG_PACKAGE_samba36-server=y" "$CONFIG_FILE"; then
        echo -e "${YELLOW}⚠️  Samba 需要 samba36-server${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓ Samba 依赖满足${NC}"
    fi
fi

echo ""

# 统计信息
echo -e "${YELLOW}[5/6] 统计配置信息...${NC}"

TOTAL_PACKAGES=$(grep -c "CONFIG_PACKAGE_" "$CONFIG_FILE" || echo 0)
ENABLED_PACKAGES=$(grep -c "=y" "$CONFIG_FILE" || echo 0)
DISABLED_PACKAGES=$(grep -c "=n" "$CONFIG_FILE" || echo 0)

echo "  总配置项：${TOTAL_PACKAGES}"
echo "  已启用：${ENABLED_PACKAGES}"
echo "  已禁用：${DISABLED_PACKAGES}"
echo "  预估固件大小：$((ENABLED_PACKAGES * 200)) KB"
echo ""

# 最终总结
echo -e "${YELLOW}[6/6] 验证总结...${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ 配置验证通过！可以编译            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "下一步:"
    echo "1. 提交配置：git add -A && git commit -m 'update config' && git push"
    echo "2. 开始编译：https://github.com/liuziqiang78-liu/OpenWRT-CI/actions"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ 配置基本通过 (有${WARNINGS}个警告)        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "建议修复警告后编译"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ 发现${ERRORS}个错误，无法编译             ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "请修复错误后重试"
    exit 1
fi
