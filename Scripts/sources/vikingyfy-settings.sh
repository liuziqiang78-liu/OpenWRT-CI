#!/bin/bash
# ============================================================
# VIKINGYFY/immortalwrt 源码专用设置
# 非 NSS 源码，需要禁用 NSS feed
# ============================================================

echo "🔧 应用 VIKINGYFY 源码专用配置..."

# VIKINGYFY 不是 NSS 源码，禁用 NSS feed 避免编译报错
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]] || [[ "${WRT_TARGET^^}" == *"IPQ"* ]]; then
    echo ""
    echo "📡 配置 VIKINGYFY QUALCOMMAX 平台..."

    # 禁用 NSS 相关 feed（VIKINGYFY 不含 NSS 包）
    echo "CONFIG_FEED_nss_packages=n" >> .config
    echo "CONFIG_FEED_sqm_scripts_nss=n" >> .config

    # SQM 使用标准版本（非 NSS 版）
    echo "CONFIG_PACKAGE_luci-app-sqm=y" >> .config
    echo "# CONFIG_PACKAGE_sqm-scripts-nss is not set" >> .config

    # 通用 USB 串口
    echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> .config

    # 无 WiFi 配置
    DTS_PATH="./target/linux/qualcommax/dts/"
    if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
        find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
        echo "✅ QUALCOMMAX nowifi DTS 已配置"
    fi

    echo "✅ VIKINGYFY QUALCOMMAX 配置完成 (无 NSS)"
fi

echo "✅ VIKINGYFY 源码专用配置完成"
