#!/bin/bash
# ============================================================
# 通用设置 - 所有源码共享的基础配置
# ============================================================

# 设置默认值（防止变量未定义导致 sed 异常）
WRT_MARK="${WRT_MARK:-Custom}"
WRT_DATE="${WRT_DATE:-$(date +%Y%m%d)}"

# 移除 luci-app-attendedsysupgrade
_collections_makefile=$(find ./feeds/luci/collections/ -type f -name "Makefile" 2>/dev/null | head -1)
if [ -n "$_collections_makefile" ]; then
    sed -i "/attendedsysupgrade/d" "$_collections_makefile"
fi

# 修改默认主题 (none 时跳过，使用源码默认主题)
if [ "$WRT_THEME" != "none" ] && [ -n "$_collections_makefile" ]; then
    sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" "$_collections_makefile"
fi

# 修改 immortalwrt.lan 关联 IP
_flash_js=$(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js" 2>/dev/null | head -1)
if [ -n "$_flash_js" ]; then
    sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" "$_flash_js"
fi

# 添加编译日期标识
_system_js=$(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js" 2>/dev/null | head -1)
if [ -n "$_system_js" ]; then
    sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" "$_system_js"
fi

# ========== WiFi 配置 ==========
WIFI_SH=$(find ./target/linux/ -path "*/base-files/etc/uci-defaults/*set-wireless.sh" -type f 2>/dev/null | head -1)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -n "$WIFI_SH" ] && [ -f "$WIFI_SH" ]; then
    sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" "$WIFI_SH"
    sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" "$WIFI_SH"
elif [ -f "$WIFI_UC" ]; then
    sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" "$WIFI_UC"
    sed -i "s/key='.*'/key='$WRT_WORD'/g" "$WIFI_UC"
    sed -i "s/country='.*'/country='CN'/g" "$WIFI_UC"
    sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" "$WIFI_UC"
fi

# ========== 路由器基础配置 ==========
CFG_FILE="./package/base-files/files/bin/config_generate"
if [ -f "$CFG_FILE" ]; then
    sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" "$CFG_FILE"
    sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" "$CFG_FILE"
else
    echo "⚠️  config_generate 不存在，跳过路由器基础配置"
fi

# ========== 登录密码配置 ==========
if [ -n "$WRT_PW" ]; then
    echo ""
    echo "🔧 配置登录密码..."
    
    # 方法 1: 通过 uci-defaults 脚本在首次启动时设置密码
    mkdir -p ./files/etc/uci-defaults
    cat > ./files/etc/uci-defaults/99-set-password << PASSWDEOF
#!/bin/sh
# 设置 root 密码 (首次启动时执行)
passwd root << EOF
$WRT_PW
$WRT_PW
EOF
PASSWDEOF
    chmod +x ./files/etc/uci-defaults/99-set-password
    echo "✅ 登录密码已通过 uci-defaults 脚本设置"
    
    # 方法 2: 同时修改 shadow 文件（双保险，部分固件 uci-defaults 可能不生效）
    SHADOW_FILE="./package/base-files/files/etc/shadow"
    if [ -f "$SHADOW_FILE" ]; then
        # 生成密码哈希 (使用 openssl)
        PW_HASH=$(openssl passwd -6 "$WRT_PW" 2>/dev/null || openssl passwd -1 "$WRT_PW" 2>/dev/null)
        if [ -n "$PW_HASH" ]; then
            sed -i "s|^root::|root:${PW_HASH}:|" "$SHADOW_FILE"
            echo "✅ 登录密码已写入 shadow 文件 (hash)"
        else
            echo "⚠️  无法生成密码哈希，仅依赖 uci-defaults 脚本"
        fi
    fi
else
    echo "ℹ️  未设置登录密码，保持默认 (无密码)"
fi

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
# 禁用 nftset，当前 iptables 配置下 fw4 表不存在，nftset 无意义
echo "CONFIG_PACKAGE_dnsmasq_full_nftset=n" >> ./.config
echo "CONFIG_PACKAGE_odhcpd=y" >> ./.config
echo "# CONFIG_PACKAGE_odhcpd-ipv6only is not set" >> ./.config
echo "CONFIG_PACKAGE_uhttpd=y" >> ./.config
echo "CONFIG_PACKAGE_uhttpd-ubus=y" >> ./.config

# ========== 防火墙 (强制使用纯 iptables) ==========
echo "# 使用纯 iptables 防火墙" >> ./.config
echo "# CONFIG_PACKAGE_firewall4 is not set" >> ./.config
echo "CONFIG_PACKAGE_firewall=y" >> ./.config
echo "CONFIG_PACKAGE_iptables=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-conntrack-extra=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-filter=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-ipopt=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-nat-extra=y" >> ./.config

# UPnP (基础插件，所有固件强制包含)
echo "CONFIG_PACKAGE_luci-app-upnp=y" >> ./.config
echo "CONFIG_PACKAGE_miniupnpd-iptables=y" >> ./.config
echo "# CONFIG_PACKAGE_miniupnpd-nftables is not set" >> ./.config

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
