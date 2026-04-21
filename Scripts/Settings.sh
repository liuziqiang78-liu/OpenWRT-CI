#!/bin/bash
# ============================================================
# Settings.sh - 设置调度入口
# 保持向后兼容，内部调用新的分模块设置
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 如果有新的分模块脚本，使用它
if [ -f "$SCRIPT_DIR/sources/apply-settings.sh" ]; then
    # 导出必要变量（WRT_SOURCE 可能未设置）
    export WRT_SOURCE="${WRT_SOURCE:-VIKINGYFY/immortalwrt}"
    source "$SCRIPT_DIR/sources/apply-settings.sh"
    exit $?
fi

# ============================================================
# 以下为旧版兼容代码（无分模块脚本时回退）
# ============================================================

# 移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
# 修改默认主题 (none 时跳过，使用源码默认主题)
if [ "$WRT_THEME" != "none" ]; then
    sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
fi
# 修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
# 添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

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

CFG_FILE="./package/base-files/files/bin/config_generate"
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
if [ "$WRT_THEME" != "none" ]; then
    echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
    echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config
fi

echo "# 核心系统包" >> ./.config
echo "CONFIG_PACKAGE_dnsmasq-full=y" >> ./.config
echo "CONFIG_PACKAGE_odhcpd=y" >> ./.config
echo "# CONFIG_PACKAGE_odhcpd-ipv6only is not set" >> ./.config
echo "CONFIG_PACKAGE_uhttpd=y" >> ./.config
echo "CONFIG_PACKAGE_uhttpd-ubus=y" >> ./.config
echo "# 使用纯 iptables 防火墙" >> ./.config
echo "# CONFIG_PACKAGE_firewall4 is not set" >> ./.config
echo "CONFIG_PACKAGE_firewall=y" >> ./.config
echo "CONFIG_PACKAGE_iptables=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-conntrack-extra=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-filter=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-ipopt=y" >> ./.config
echo "CONFIG_PACKAGE_iptables-mod-nat-extra=y" >> ./.config

if [ -n "$WRT_PACKAGE" ] && [[ "$WRT_PACKAGE" == *"luci-app-upnp"* ]]; then
    echo "CONFIG_PACKAGE_miniupnpd-iptables=y" >> ./.config
    echo "# CONFIG_PACKAGE_miniupnpd-nftables is not set" >> ./.config
fi

if [ -n "$WRT_PACKAGE" ]; then
    echo -e "$WRT_PACKAGE" >> ./.config
fi

TARGET_ARCH=$(grep "^CONFIG_TARGET_BOARD=" .config | cut -d'=' -f2 | sed 's/"//g')
ARCH="aarch64_cortex-a53"
if [[ "${WRT_TARGET^^}" == *"X86"* ]]; then ARCH="x86_64"
elif [[ "${WRT_TARGET^^}" == *"ARMV7"* ]]; then ARCH="arm_cortex-a15_neon-vfpv4"
elif [[ "${WRT_TARGET^^}" == *"ARMV8"* ]]; then ARCH="aarch64_cortex-a53"
elif [[ "${WRT_TARGET^^}" == *"MIPS"* ]]; then ARCH="mips_24kc"
elif [[ "${WRT_TARGET^^}" == *"IPQ"* ]] || [[ "${WRT_TARGET^^}" == *"QUALCOMM"* ]]; then ARCH="aarch64_generic"
elif [[ "${WRT_TARGET^^}" == *"MEDIATEK"* ]]; then ARCH="aarch64_cortex-a53"
elif [[ "${WRT_TARGET^^}" == *"ROCKCHIP"* ]]; then ARCH="aarch64_cortex-a53"
fi

DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
    echo "CONFIG_FEED_nss_packages=n" >> ./.config
    echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
    echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
    echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
    echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
    if [[ "${WRT_CONFIG,,}" == *"ipq50"* ]]; then
        echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
    else
        echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
    fi
    if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
        find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
    fi
    echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> ./.config
fi
