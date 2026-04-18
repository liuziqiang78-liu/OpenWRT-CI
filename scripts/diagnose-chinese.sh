#!/bin/sh
# 中文语言支持诊断脚本
# 通过SSH连接到路由器运行此脚本

LOG_FILE="/tmp/chinese-diagnose-$(date +%s).log"

echo "🔍 开始中文语言支持诊断..." | tee -a $LOG_FILE
echo "时间: $(date)" | tee -a $LOG_FILE
echo "======================================" | tee -a $LOG_FILE

# 1. 检查系统基本信息
echo "1. 📋 系统基本信息:" | tee -a $LOG_FILE
echo "  主机名: $(cat /proc/sys/kernel/hostname 2>/dev/null || echo unknown)" | tee -a $LOG_FILE
echo "  内核版本: $(uname -r)" | tee -a $LOG_FILE
echo "  固件版本: $(cat /etc/openwrt_release 2>/dev/null | grep 'DISTRIB_DESCRIPTION' | cut -d'=' -f2 | tr -d \"'\" || echo unknown)" | tee -a $LOG_FILE
echo "  CPU架构: $(opkg print-architecture 2>/dev/null | head -1 | cut -d' ' -f2 || echo unknown)" | tee -a $LOG_FILE

# 2. 检查语言设置
echo "" | tee -a $LOG_FILE
echo "2. 🌐 语言设置:" | tee -a $LOG_FILE
if [ -f /etc/config/luci ]; then
    LUCI_LANG=$(uci get luci.main.lang 2>/dev/null || echo "未设置")
    echo "  Luci语言: $LUCI_LANG" | tee -a $LOG_FILE
    echo "  Luci配置文件: /etc/config/luci" | tee -a $LOG_FILE
    echo "  文件内容摘要:" | tee -a $LOG_FILE
    grep -E "lang|theme" /etc/config/luci | tee -a $LOG_FILE
else
    echo "  ❌ /etc/config/luci 不存在" | tee -a $LOG_FILE
fi

# 3. 检查环境变量
echo "" | tee -a $LOG_FILE
echo "3. 🔧 环境变量:" | tee -a $LOG_FILE
env | grep -i "lang\|locale\|lc_all" | tee -a $LOG_FILE || echo "  未找到相关环境变量" | tee -a $LOG_FILE

# 4. 检查已安装的包
echo "" | tee -a $LOG_FILE
echo "4. 📦 已安装的中文语言包:" | tee -a $LOG_FILE
CHINESE_PACKAGES=$(opkg list-installed 2>/dev/null | grep -i "zh-cn\|zh_CN\|i18n.*zh" | tee -a $LOG_FILE)
if [ -z "$CHINESE_PACKAGES" ]; then
    echo "  ❌ 未安装任何中文语言包" | tee -a $LOG_FILE
else
    echo "  ✅ 已安装中文语言包" | tee -a $LOG_FILE
fi

# 5. 检查可用的包
echo "" | tee -a $LOG_FILE
echo "5. 🔎 可用的中文语言包:" | tee -a $LOG_FILE
opkg update 2>&1 >/dev/null
AVAILABLE_PACKAGES=$(opkg list 2>/dev/null | grep -i "luci-i18n.*zh" | head -10 | tee -a $LOG_FILE)
if [ -z "$AVAILABLE_PACKAGES" ]; then
    echo "  ❌ 软件源中没有中文语言包" | tee -a $LOG_FILE
else
    echo "  ✅ 软件源中有中文语言包" | tee -a $LOG_FILE
fi

# 6. 检查首次启动脚本
echo "" | tee -a $LOG_FILE
echo "6. ⚡ 首次启动脚本状态:" | tee -a $LOG_FILE
if [ -f /etc/uci-defaults/99-set-chinese-language ]; then
    echo "  ⚠️  脚本未执行 (仍存在)" | tee -a $LOG_FILE
elif [ -f /etc/uci-defaults/99-set-chinese-language.done ]; then
    echo "  ✅ 脚本已执行完成" | tee -a $LOG_FILE
    echo "  日志文件: /tmp/set-chinese-language.log" | tee -a $LOG_FILE
    if [ -f /tmp/set-chinese-language.log ]; then
        echo "  最后10行日志:" | tee -a $LOG_FILE
        tail -10 /tmp/set-chinese-language.log | tee -a $LOG_FILE
    fi
else
    echo "  ❓ 脚本文件不存在" | tee -a $LOG_FILE
fi

# 7. 检查网络连接
echo "" | tee -a $LOG_FILE
echo "7. 🌐 网络连接测试:" | tee -a $LOG_FILE
if ping -c 1 -W 2 openwrt.org >/dev/null 2>&1; then
    echo "  ✅ 可以访问 openwrt.org" | tee -a $LOG_FILE
else
    echo "  ❌ 无法访问 openwrt.org" | tee -a $LOG_FILE
fi

# 8. 建议操作
echo "" | tee -a $LOG_FILE
echo "8. 💡 建议操作:" | tee -a $LOG_FILE

if [ -z "$CHINESE_PACKAGES" ] && [ -n "$AVAILABLE_PACKAGES" ]; then
    echo "  建议安装中文语言包:" | tee -a $LOG_FILE
    FIRST_PACKAGE=$(echo "$AVAILABLE_PACKAGES" | head -1 | cut -d' ' -f1)
    echo "  opkg install $FIRST_PACKAGE" | tee -a $LOG_FILE
elif [ -z "$AVAILABLE_PACKAGES" ]; then
    echo "  建议检查网络连接和软件源配置" | tee -a $LOG_FILE
    echo "  1. 检查 /etc/opkg/distfeeds.conf" | tee -a $LOG_FILE
    echo "  2. 运行: opkg update" | tee -a $LOG_FILE
elif [ "$LUCI_LANG" != "zh_cn" ]; then
    echo "  建议设置语言为中文:" | tee -a $LOG_FILE
    echo "  uci set luci.main.lang=zh_cn" | tee -a $LOG_FILE
    echo "  uci commit luci" | tee -a $LOG_FILE
    echo "  /etc/init.d/uhttpd restart" | tee -a $LOG_FILE
else
    echo "  ✅ 系统配置正常" | tee -a $LOG_FILE
    echo "  如果仍然显示英文，请重启路由器或Luci服务" | tee -a $LOG_FILE
fi

echo "" | tee -a $LOG_FILE
echo "======================================" | tee -a $LOG_FILE
echo "诊断完成! 日志文件: $LOG_FILE" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "📋 快速修复命令:" | tee -a $LOG_FILE
echo "1. 设置中文语言: uci set luci.main.lang=zh_cn && uci commit luci && /etc/init.d/uhttpd restart" | tee -a $LOG_FILE
echo "2. 安装中文包: opkg update && opkg install luci-i18n-base-zh-cn" | tee -a $LOG_FILE
echo "3. 检查服务: /etc/init.d/uhttpd status" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "需要更多帮助? 请提供此日志文件内容。" | tee -a $LOG_FILE