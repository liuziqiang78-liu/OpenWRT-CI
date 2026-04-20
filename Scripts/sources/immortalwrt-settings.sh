#!/bin/bash
# ============================================================
# immortalwrt/immortalwrt 官方源码专用设置
# 非 NSS 源码，需要禁用 NSS feed
# ============================================================

echo "🔧 应用 immortalwrt 官方源码专用配置..."

# 官方 immortalwrt 不含 NSS，禁用 NSS feed
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]] || [[ "${WRT_TARGET^^}" == *"IPQ"* ]]; then
    echo ""
    echo "📡 配置 immortalwrt QUALCOMMAX 平台..."

    # 禁用 NSS 相关 feed
    echo "CONFIG_FEED_nss_packages=n" >> .config
    echo "CONFIG_FEED_sqm_scripts_nss=n" >> .config

    # SQM 使用标准版本
    echo "CONFIG_PACKAGE_luci-app-sqm=y" >> .config
    echo "# CONFIG_PACKAGE_sqm-scripts-nss is not set" >> .config

    echo "✅ immortalwrt QUALCOMMAX 配置完成 (无 NSS)"
fi

echo "✅ immortalwrt 官方源码专用配置完成"
