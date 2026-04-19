#!/bin/bash

# 移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
# 修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
# 修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
# 添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax,rockchip/armv8,x86}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
    # 修改WIFI名称
    sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
    # 修改WIFI密码
    sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
    # 修改WIFI名称
    sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
    # 修改WIFI密码
    sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
    # 修改WIFI地区
    sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
    # 修改WIFI加密
    sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
# 修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
# 修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

# 配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

# 添加防火墙核心包
echo "# 核心系统包" >> ./.config
echo "CONFIG_PACKAGE_firewall4=y" >> ./.config
echo "CONFIG_PACKAGE_dnsmasq-full=y" >> ./.config
echo "CONFIG_PACKAGE_odhcpd=y" >> ./.config
echo "CONFIG_PACKAGE_uhttpd=y" >> ./.config
echo "CONFIG_PACKAGE_uhttpd-ubus=y" >> ./.config
# 添加iptables相关配置 (使用 iptables-nft 兼容 firewall4)
echo "# 使用iptables-nft兼容firewall4" >> ./.config
echo "CONFIG_PACKAGE_iptables-nft=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-conntrack-extra=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-filter=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-ipopt=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-nat-extra=y" >> ./.config

# 确保UPnP服务与iptables兼容
if [ -n "$WRT_PACKAGE" ] && [[ "$WRT_PACKAGE" == *"luci-app-upnp"* ]]; then
    # 如果启用了UPnP应用，则确保依赖项正确
    echo "CONFIG_PACKAGE_miniupnpd-nftables=y" >> ./.config
    echo "# CONFIG_PACKAGE_miniupnpd-iptables is not set" >> ./.config
fi

# 手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
    echo -e "$WRT_PACKAGE" >> ./.config
fi

# 根据目标架构动态设置软件源
TARGET_ARCH=$(grep "^CONFIG_TARGET_BOARD=" .config | cut -d'=' -f2 | sed 's/"//g')

# 默认使用 aarch64_cortex-a53 架构作为 fallback
ARCH="aarch64_cortex-a53"

# 根据目标平台确定正确的架构
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

# 替换软件源为Vsean镜像
DISTFEEDS_CONF="./repositories.conf"
if [ -f "$DISTFEEDS_CONF" ]; then
    echo "# Vsean OpenWrt Mirror" > $DISTFEEDS_CONF.new
    echo "src/gz openwrt_base https://mirrors.vsean.net/openwrt/releases/24.10-SNAPSHOT/packages/$ARCH/base/" >> $DISTFEEDS_CONF.new
    echo "src/gz openwrt_luci https://mirrors.vsean.net/openwrt/releases/24.10-SNAPSHOT/packages/$ARCH/luci/" >> $DISTFEEDS_CONF.new
    echo "src/gz openwrt_packages https://mirrors.vsean.net/openwrt/releases/24.10-SNAPSHOT/packages/$ARCH/packages/" >> $DISTFEEDS_CONF.new
    echo "src/gz openwrt_routing https://mirrors.vsean.net/openwrt/releases/24.10-SNAPSHOT/packages/$ARCH/routing/" >> $DISTFEEDS_CONF.new
    echo "src/gz openwrt_telephony https://mirrors.vsean.net/openwrt/releases/24.10-SNAPSHOT/packages/$ARCH/telephony/" >> $DISTFEEDS_CONF.new
    mv $DISTFEEDS_CONF.new $DISTFEEDS_CONF
    echo "Updated package feeds to Vsean mirror sources for $ARCH architecture"
else
    # 如果 repositories.conf 不存在，则尝试 distfeeds.conf 路径
    DISTFEEDS_CONF_ALT="./packagefeeds.conf"
    if [ -f "$DISTFEEDS_CONF_ALT" ]; then
        echo "# Vsean OpenWrt Mirror" > $DISTFEEDS_CONF_ALT.new
        echo "src/gz openwrt_base https://mirrors.vsean.net/openwrt/releases/24.10-SNAPSHOT/packages/$ARCH/base/" >> $DISTFEEDS_CONF_ALT.new
        echo "src/gz openwrt_luci https://mirrors.vsean.net/openwrt/releases/24.10-SNAPSHOT/packages/$ARCH/luci/" >> $DISTFEEDS_CONF_ALT.new
        echo "src/gz openwrt_packages https://mirrors.vsean.net/openwrt/releases/24.10-SNAPSHOT/packages/$ARCH/packages/" >> $DISTFEEDS_CONF_ALT.new
        echo "src/gz openwrt_routing https://mirrors.vsean.net/openwrt/releases/24.10-SNAPSHOT/packages/$ARCH/routing/" >> $DISTFEEDS_CONF_ALT.new
        echo "src/gz openwrt_telephony https://mirrors.vsean.net/openwrt/releases/24.10-SNAPSHOT/packages/$ARCH/telephony/" >> $DISTFEEDS_CONF_ALT.new
        mv $DISTFEEDS_CONF_ALT.new $DISTFEEDS_CONF_ALT
        echo "Updated package feeds to Vsean mirror sources for $ARCH architecture (alt path)"
    fi
fi

# 高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
    # 取消nss相关feed
    echo "CONFIG_FEED_nss_packages=n" >> ./.config
    echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
    # 开启sqm-nss插件
    echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
    echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
    # 设置NSS版本
    echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
    if [[ "${WRT_CONFIG,,}" == *"ipq50"* ]]; then
        echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
    else
        echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
    fi
    # 无WIFI配置调整Q6大小
    if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
        find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
        echo "qualcommax set up nowifi successfully!"
    fi
    # 其他调整
    echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> ./.config
fi