#!/bin/bash

# OpenWRT 插件安装工具
# 支持指定版本安装

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 插件配置目录
PLUGIN_DIR="./wrt/package"

# 显示用法
usage() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   OpenWRT 插件安装工具                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "用法：$0 <插件名> [版本号]"
    echo ""
    echo "支持的插件:"
    echo "  openclash      - OpenClash"
    echo "  passwall       - PassWall"
    echo "  passwall2      - PassWall2"
    echo "  homeproxy      - HomeProxy"
    echo "  diskman        - DiskMan"
    echo "  tailscale      - Tailscale"
    echo "  ddns-go        - DDNS-GO"
    echo "  aria2          - Aria2"
    echo "  qbittorrent    - Qbittorrent"
    echo "  easytier       - EasyTier"
    echo "  vnt            - VNT"
    echo ""
    echo "示例:"
    echo "  $0 openclash v0.45.87"
    echo "  $0 passwall v2.8.3"
    echo "  $0 homeproxy        # 使用最新版本"
    echo ""
    exit 1
}

# 检查参数
if [ -z "$1" ]; then
    usage
fi

PLUGIN_NAME=$1
PLUGIN_VERSION=$2

echo ""
echo -e "${CYAN}正在安装插件：${GREEN}${PLUGIN_NAME}${NC}"
if [ -n "$PLUGIN_VERSION" ]; then
    echo -e "目标版本：${GREEN}${PLUGIN_VERSION}${NC}"
fi
echo ""

# 克隆插件仓库
install_plugin() {
    local plugin=$1
    local repo=$2
    local version=$3
    
    echo -e "${YELLOW}克隆：${repo}${NC}"
    
    if [ -n "$version" ]; then
        # 安装指定版本
        if git clone --depth=1 --branch "$version" "https://github.com/${repo}.git" "./${plugin}/" 2>/dev/null; then
            echo -e "${GREEN}✓ 安装成功 (版本：${version})${NC}"
        else
            echo -e "${RED}✗ 版本 ${version} 不存在，尝试安装最新版本...${NC}"
            git clone --depth=1 "https://github.com/${repo}.git" "./${plugin}/"
            echo -e "${YELLOW}⚠ 已安装最新版本${NC}"
        fi
    else
        # 安装最新版本
        git clone --depth=1 "https://github.com/${repo}.git" "./${plugin}/"
        echo -e "${GREEN}✓ 安装成功 (最新版本)${NC}"
    fi
}

# 进入插件目录
cd "$PLUGIN_DIR"

# 根据插件名称安装
case $PLUGIN_NAME in
    openclash)
        install_plugin "openclash" "vernesong/OpenClash" "$PLUGIN_VERSION"
        ;;
    passwall)
        install_plugin "passwall" "Openwrt-Passwall/openwrt-passwall" "$PLUGIN_VERSION"
        ;;
    passwall2)
        install_plugin "passwall2" "Openwrt-Passwall/openwrt-passwall2" "$PLUGIN_VERSION"
        ;;
    homeproxy)
        install_plugin "homeproxy" "VIKINGYFY/homeproxy" "$PLUGIN_VERSION"
        ;;
    diskman)
        install_plugin "luci-app-diskman" "lisaac/luci-app-diskman" "$PLUGIN_VERSION"
        ;;
    tailscale)
        install_plugin "luci-app-tailscale" "Tokisaki-Galaxy/luci-app-tailscale-community" "$PLUGIN_VERSION"
        ;;
    ddns-go)
        install_plugin "luci-app-ddns-go" "sirpdboy/luci-app-ddns-go" "$PLUGIN_VERSION"
        ;;
    aria2)
        install_plugin "luci-app-aria2" "sbwml/luci-app-aria2" "$PLUGIN_VERSION"
        ;;
    qbittorrent)
        install_plugin "luci-app-qbittorrent" "sbwml/luci-app-qbittorrent" "$PLUGIN_VERSION"
        ;;
    easytier)
        install_plugin "luci-app-easytier" "EasyTier/luci-app-easytier" "$PLUGIN_VERSION"
        ;;
    vnt)
        install_plugin "luci-app-vnt" "lmq8267/luci-app-vnt" "$PLUGIN_VERSION"
        ;;
    argon)
        install_plugin "luci-theme-argon" "sbwml/luci-theme-argon" "$PLUGIN_VERSION"
        ;;
    aurora)
        install_plugin "luci-theme-aurora" "eamonxg/luci-theme-aurora" "$PLUGIN_VERSION"
        ;;
    kucat)
        install_plugin "luci-theme-kucat" "sirpdboy/luci-theme-kucat" "$PLUGIN_VERSION"
        ;;
    *)
        echo -e "${RED}✗ 不支持的插件：${PLUGIN_NAME}${NC}"
        echo ""
        usage
        ;;
esac

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}插件安装完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "下一步:"
echo "1. 继续安装其他插件"
echo "2. 生成配置：make defconfig"
echo "3. 编译固件：make -j\$(nproc)"
echo ""
