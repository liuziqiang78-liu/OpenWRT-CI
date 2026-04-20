#!/bin/bash
# ============================================================
# 通用设置 - 所有源码共享的基础配置
# ============================================================

# 移除 luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 修改默认主题 (none 时跳过，使用源码默认主题)
if [ "$WRT_THEME" != "none" ]; then
    sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
fi

# 修改 immortalwrt.lan 关联 IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")

# 添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

# ========== WiFi 配置 ==========
WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax,rockchip/armv8,x86}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
    sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
    sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
    sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
    sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
    sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
    sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

# ========== 路由器基础配置 ==========
CFG_FILE="./package/base-files/files/bin/config_generate"
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

# ========== LuCI 基础配置 ==========
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
if [ "$WRT_THEME" != "none" ]; then
    echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
    echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config
fi

# ========== 核心系统包 ==========
echo "# 核心系统包" >> ./.config
echo "CONFIG_PACKAGE_dnsmasq-full=y" >> ./.config
echo "CONFIG_PACKAGE_odhcpd=y" >> ./.config
echo "# CONFIG_PACKAGE_odhcpd-ipv6only is not set" >> ./.config
echo "CONFIG_PACKAGE_uhttpd=y" >> ./.config
echo "CONFIG_PACKAGE_uhttpd-ubus=y" >> ./.config

# ========== 防火墙 ==========
if [ "$WRT_FIREWALL" = "iptables" ]; then
    echo "# 用户选择 iptables" >> ./.config
    echo "# CONFIG_PACKAGE_firewall4 is not set" >> ./.config
    echo "CONFIG_PACKAGE_firewall=y" >> ./.config
    echo "CONFIG_PACKAGE_iptables=y" >> ./.config
else
    echo "# 用户选择 firewall4 (默认)" >> ./.config
    echo "CONFIG_PACKAGE_firewall4=y" >> ./.config
    echo "# 使用 iptables-nft 兼容 firewall4" >> ./.config
    echo "CONFIG_PACKAGE_iptables-nft=y" >> ./.config
fi
echo "CONFIG_PACKAGE_iptables-mod-conntrack-extra=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-filter=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-ipopt=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-nat-extra=y" >> ./.config

# UPnP 兼容
if [ -n "$WRT_PACKAGE" ] && [[ "$WRT_PACKAGE" == *"luci-app-upnp"* ]]; then
    echo "CONFIG_PACKAGE_miniupnpd-nftables=y" >> ./.config
    echo "# CONFIG_PACKAGE_miniupnpd-iptables is not set" >> ./.config
fi

# 手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
    echo -e "$WRT_PACKAGE" >> ./.config
fi

# ========== 架构检测 ==========
TARGET_ARCH=$(grep "^CONFIG_TARGET_BOARD=" .config | cut -d'=' -f2 | sed 's/"//g')
ARCH="aarch64_cortex-a53"

if [[ "${WRT_TARGET^^}" == *"X86"* ]]; then
    ARCH="x86_64"
elif [[ "${WRT_TARGET^^}" == *"ARMV7"* ]]; then
    ARCH="arm_cortex-a15_neon-vfpv4"
elif [[ "${WRT_TARGET^^}" == *"ARMV8"* ]]; then
    ARCH="aarch64_cortex-a53"
elif [[ "${WRT_TARGET^^}" == *"MIPS"* ]]; then
    ARCH="mips_24kc"
elif [[ "${WRT_TARGET^^}" == *"IPQ"* ]] || [[ "${WRT_TARGET^^}" == *"QUALCOMM"* ]]; then
    ARCH="aarch64_generic"
elif [[ "${WRT_TARGET^^}" == *"MEDIATEK"* ]]; then
    ARCH="aarch64_cortex-a53"
elif [[ "${WRT_TARGET^^}" == *"ROCKCHIP"* ]]; then
    ARCH="aarch64_cortex-a53"
fi

echo "Detected target architecture: $ARCH for target ${WRT_TARGET}"

# ========== OpenWrt 版本号检测 ==========
OPENWRT_VERSION="24.10-SNAPSHOT"
if [ -f "./include/version.mk" ]; then
    DETECTED_VER=$(grep -oP 'VERSION_NUMBER:=\K[^"]+' ./include/version.mk 2>/dev/null | head -1)
    if [ -n "$DETECTED_VER" ]; then
        OPENWRT_VERSION="$DETECTED_VER"
        echo "Detected OpenWrt version: $OPENWRT_VERSION"
    fi
elif [ -f "./version" ]; then
    OPENWRT_VERSION=$(cat ./version 2>/dev/null | head -1)
    echo "Detected OpenWrt version from ./version: $OPENWRT_VERSION"
fi

# ========== 软件源替换 ==========
DISTFEEDS_CONF="./repositories.conf"
if [ -f "$DISTFEEDS_CONF" ]; then
    echo "# Vsean OpenWrt Mirror" > $DISTFEEDS_CONF.new
    echo "src/gz openwrt_base https://mirrors.vsean.net/openwrt/releases/$OPENWRT_VERSION/packages/$ARCH/base/" >> $DISTFEEDS_CONF.new
    echo "src/gz openwrt_luci https://mirrors.vsean.net/openwrt/releases/$OPENWRT_VERSION/packages/$ARCH/luci/" >> $DISTFEEDS_CONF.new
    echo "src/gz openwrt_packages https://mirrors.vsean.net/openwrt/releases/$OPENWRT_VERSION/packages/$ARCH/packages/" >> $DISTFEEDS_CONF.new
    echo "src/gz openwrt_routing https://mirrors.vsean.net/openwrt/releases/$OPENWRT_VERSION/packages/$ARCH/routing/" >> $DISTFEEDS_CONF.new
    echo "src/gz openwrt_telephony https://mirrors.vsean.net/openwrt/releases/$OPENWRT_VERSION/packages/$ARCH/telephony/" >> $DISTFEEDS_CONF.new
    mv $DISTFEEDS_CONF.new $DISTFEEDS_CONF
    echo "Updated package feeds to Vsean mirror sources for $ARCH architecture (version: $OPENWRT_VERSION)"
else
    DISTFEEDS_CONF_ALT="./packagefeeds.conf"
    if [ -f "$DISTFEEDS_CONF_ALT" ]; then
        echo "# Vsean OpenWrt Mirror" > $DISTFEEDS_CONF_ALT.new
        echo "src/gz openwrt_base https://mirrors.vsean.net/openwrt/releases/$OPENWRT_VERSION/packages/$ARCH/base/" >> $DISTFEEDS_CONF_ALT.new
        echo "src/gz openwrt_luci https://mirrors.vsean.net/openwrt/releases/$OPENWRT_VERSION/packages/$ARCH/luci/" >> $DISTFEEDS_CONF_ALT.new
        echo "src/gz openwrt_packages https://mirrors.vsean.net/openwrt/releases/$OPENWRT_VERSION/packages/$ARCH/packages/" >> $DISTFEEDS_CONF_ALT.new
        echo "src/gz openwrt_routing https://mirrors.vsean.net/openwrt/releases/$OPENWRT_VERSION/packages/$ARCH/routing/" >> $DISTFEEDS_CONF_ALT.new
        echo "src/gz openwrt_telephony https://mirrors.vsean.net/openwrt/releases/$OPENWRT_VERSION/packages/$ARCH/telephony/" >> $DISTFEEDS_CONF_ALT.new
        mv $DISTFEEDS_CONF_ALT.new $DISTFEEDS_CONF_ALT
        echo "Updated package feeds to Vsean mirror sources for $ARCH architecture (alt path, version: $OPENWRT_VERSION)"
    fi
fi
