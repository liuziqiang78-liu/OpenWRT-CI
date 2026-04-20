#!/bin/bash
# ============================================================
# qosmio/openwrt-ipq 源码专用设置
# NSS 源码，保留 NSS feed
# ============================================================

echo "🔧 应用 qosmio 源码专用配置..."

if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]] || [[ "${WRT_TARGET^^}" == *"IPQ"* ]]; then
    echo ""
    echo "📡 配置 qosmio NSS 硬件加速..."

    # qosmio 是 NSS 源码，保留 NSS feed
    # 加载 NSS 包配置
    NSS_CONFIG="$GITHUB_WORKSPACE/Config/sources/libwrt"
    case "${WRT_CONFIG,,}" in
        *ipq807x*)
            [ -f "$NSS_CONFIG/nss-ipq807x.txt" ] && cat "$NSS_CONFIG/nss-ipq807x.txt" >> .config && echo "✅ 已加载 IPQ807X NSS 配置"
            ;;
        *ipq60xx*)
            [ -f "$NSS_CONFIG/nss-ipq60xx.txt" ] && cat "$NSS_CONFIG/nss-ipq60xx.txt" >> .config && echo "✅ 已加载 IPQ60XX NSS 配置"
            ;;
        *ipq50xx*)
            [ -f "$NSS_CONFIG/nss-ipq50xx.txt" ] && cat "$NSS_CONFIG/nss-ipq50xx.txt" >> .config && echo "✅ 已加载 IPQ50XX NSS 配置"
            ;;
    esac

    # NSS 固件版本
    NSS_FW_VERSION="${NSS_FIRMWARE_VERSION:-auto}"
    sed -i '/CONFIG_NSS_FIRMWARE_VERSION/d' .config 2>/dev/null

    case "$NSS_FW_VERSION" in
        11_4) echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=y" >> .config ;;
        12_2) echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> .config ;;
        12_5) echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> .config ;;
        auto|*)
            if [[ "${WRT_CONFIG,,}" == *"ipq50"* ]]; then
                echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> .config
            else
                echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> .config
            fi
            ;;
    esac

    echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> .config

    echo "✅ qosmio NSS 配置完成"
fi

echo "✅ qosmio 源码专用配置完成"
