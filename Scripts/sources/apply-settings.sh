#!/bin/bash
# ============================================================
# 源码设置调度器 - 根据 WRT_SOURCE 分发到对应脚本
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 先执行通用设置
echo "=========================================="
echo "📋 执行通用设置"
echo "=========================================="
source "$SCRIPT_DIR/common-settings.sh"

# 根据源码仓库分发到对应脚本
echo ""
echo "=========================================="
echo "📋 执行源码专用设置: $WRT_SOURCE"
echo "=========================================="

case "$WRT_SOURCE" in
    LiBwrt/openwrt-6.x)
        source "$SCRIPT_DIR/libwrt-settings.sh"
        ;;
    VIKINGYFY/immortalwrt)
        source "$SCRIPT_DIR/vikingyfy-settings.sh"
        ;;
    immortalwrt/immortalwrt)
        source "$SCRIPT_DIR/immortalwrt-settings.sh"
        ;;
    qosmio/openwrt-ipq)
        source "$SCRIPT_DIR/qosmio-settings.sh"
        ;;
    *)
        echo "⚠️  未知源码: $WRT_SOURCE，跳过源码专用设置"
        echo "   如果是新源码，请在 Scripts/sources/ 下创建对应的 settings 脚本"
        ;;
esac

echo ""
echo "=========================================="
echo "✅ 所有设置已应用"
echo "=========================================="
