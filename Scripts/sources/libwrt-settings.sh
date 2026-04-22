#!/bin/bash
# ============================================================
# LiBwrt/openwrt-6.x 源码专用设置
# 满血 NSS 硬件加速配置
# ============================================================

echo "🔧 应用 LiBwrt 源码专用配置..."

# ========== NSS 配置 ==========
DTS_PATH="./target/linux/qualcommax/dts/"

if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]] || [[ "${WRT_TARGET^^}" == *"IPQ"* ]]; then
    echo ""
    echo "📡 配置 LiBwrt NSS 硬件加速..."

    # ------ NSS Feed 配置 ------
    # LiBwrt 源码自带 NSS 包 + 依赖 qosmio/nss-packages feed
    # 保留 feed 不禁用，确保 NSS 包可被找到
    # （区别于 VIKINGYFY 源码需要禁用 NSS feed）

    # ------ 加载 NSS 包配置 ------
    NSS_CONFIG="$GITHUB_WORKSPACE/Config/sources/libwrt"
    case "${WRT_CONFIG,,}" in
        *ipq807x*)
            if [ -f "$NSS_CONFIG/nss-ipq807x.txt" ]; then
                cat "$NSS_CONFIG/nss-ipq807x.txt" >> .config
                echo "✅ 已加载 IPQ807X NSS 满血配置"
            fi
            ;;
        *ipq60xx*)
            if [ -f "$NSS_CONFIG/nss-ipq60xx.txt" ]; then
                cat "$NSS_CONFIG/nss-ipq60xx.txt" >> .config
                echo "✅ 已加载 IPQ60XX NSS 满血配置"
            fi
            ;;
        *ipq50xx*)
            if [ -f "$NSS_CONFIG/nss-ipq50xx.txt" ]; then
                cat "$NSS_CONFIG/nss-ipq50xx.txt" >> .config
                echo "✅ 已加载 IPQ50XX NSS 配置"
            fi
            ;;
    esac

    # ------ NSS 固件版本 ------
    # 由用户在 WebUI 中选择，或使用默认值
    NSS_FW_VERSION="${NSS_FIRMWARE_VERSION:-auto}"
    echo "NSS 固件版本选择: $NSS_FW_VERSION"

    # 清除所有 NSS 固件版本选项
    sed -i '/CONFIG_NSS_FIRMWARE_VERSION/d' .config 2>/dev/null

    case "$NSS_FW_VERSION" in
        11_4)
            echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=y" >> .config
            echo "✅ NSS 固件版本: 11.4 (WDS/MESH 兼容)"
            ;;
        12_2)
            echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> .config
            echo "✅ NSS 固件版本: 12.2"
            ;;
        12_5)
            echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> .config
            echo "✅ NSS 固件版本: 12.5 (最新)"
            ;;
        auto|*)
            # 智能选择：根据平台和功能自动匹配
            if [[ "${WRT_CONFIG,,}" == *"ipq50"* ]]; then
                echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> .config
                echo "✅ NSS 固件版本: 12.2 (IPQ50XX 自动选择)"
            elif [[ "${WRT_CONFIG,,}" == *"ipq807"* ]]; then
                # IPQ807X 默认 12.5，但如果用户开了 WDS/MESH 相关插件则降级到 11.4
                if [ -n "$WRT_PACKAGE" ] && [[ "$WRT_PACKAGE" == *"easymesh"* || "$WRT_PACKAGE" == *"wds"* ]]; then
                    echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=y" >> .config
                    echo "✅ NSS 固件版本: 11.4 (检测到 WDS/MESH 插件)"
                else
                    echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> .config
                    echo "✅ NSS 固件版本: 12.5 (IPQ807X 自动选择)"
                fi
            else
                echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> .config
                echo "✅ NSS 固件版本: 12.5 (默认)"
            fi
            ;;
    esac

    # ------ USB 串口支持 ------
    echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> .config

    # ------ 无 WiFi 配置调整 ------
    if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
        find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
        echo "✅ QUALCOMMAX nowifi DTS 已配置"
    fi

    # ------ 修复 NSS 与 dnsmasq conntrack 冲突 ------
    # NSS 修改了 nf_conntrack_ecache 事件回调，dnsmasq-full 的 conntrack 功能会受影响
    # 导致 DHCPv4 无法正常工作（IPv6 走 odhcpd 不受影响）
    echo "CONFIG_PACKAGE_dnsmasq_full_conntrack=n" >> .config
    echo "✅ 高通平台：禁用 dnsmasq conntrack 避免 NSS 冲突"

    echo ""
    echo "✅ LiBwrt NSS 配置完成"
fi

# ------ 修复 IPQ807X 的 odhcpd 冲突 ------
# LiBwrt 特有：odhcpd 包定义可能与 immortalwrt 不同
if grep -q '^CONFIG_PACKAGE_odhcpd=y' .config && grep -q '^CONFIG_PACKAGE_odhcpd-ipv6only=y' .config; then
    sed -i 's/^CONFIG_PACKAGE_odhcpd-ipv6only=y/# CONFIG_PACKAGE_odhcpd-ipv6only is not set/' .config
    echo "✅ 已修复 odhcpd 与 odhcpd-ipv6only 冲突"
fi

echo "✅ LiBwrt 源码专用配置完成"
