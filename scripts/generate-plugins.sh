#!/bin/bash
# 生成每个插件的独立文件夹结构
# 每个插件文件夹包含:
#   - config.json  (插件元数据)
#   - config.mk    (OpenWRT 配置片段)

set -e
cd "$(dirname "$0")/.."

PLUGINS_DIR="./plugins"
rm -rf "$PLUGINS_DIR"
mkdir -p "$PLUGINS_DIR"

# 读取 plugin-repos.json
REPO_MAP="./plugin-repos.json"

# ========== 科学上网 ==========
create_plugin() {
    local name="$1" pkg="$2" desc="$3" features="$4" category="$5" repo="$6"
    local dir="$PLUGINS_DIR/$pkg"
    mkdir -p "$dir"
    
    cat > "$dir/config.json" << EOF
{
    "name": "$name",
    "package": "$pkg",
    "description": "$desc",
    "features": "$features",
    "category": "$category",
    "repository": "$repo"
}
EOF
    
    echo "CONFIG_PACKAGE_${pkg}=y" > "$dir/config.mk"
    echo "  ✓ $pkg"
}

echo "📦 生成插件目录结构..."
echo ""

# ========== 科学上网 (proxy) ==========
echo "🔐 科学上网:"
create_plugin "HomeProxy" "luci-app-homeproxy" "高性能代理工具" "支持多种协议、高性能转发、规则分流、日志记录" "proxy" "https://github.com/VIKINGYFY/homeproxy.git"
create_plugin "OpenClash" "luci-app-openclash" "Clash 客户端" "规则代理、节点切换、流量统计、订阅管理" "proxy" "https://github.com/vernesong/OpenClash.git"
create_plugin "PassWall" "luci-app-passwall" "综合代理工具" "多协议支持、自动切换、负载均衡" "proxy" "https://github.com/Openwrt-Passwall/openwrt-passwall.git"
create_plugin "PassWall2" "luci-app-passwall2" "PassWall 新版" "新版架构、更好性能" "proxy" "https://github.com/Openwrt-Passwall/openwrt-passwall2.git"
create_plugin "SSR-Plus" "luci-app-ssr-plus" "SS/SSR/Vmess 代理" "SS/SSR/Vmess/Trojan、规则分流" "proxy" "https://github.com/fw876/helloworld.git"
create_plugin "Nikki" "luci-app-nikki" "Mihomo 透明代理" "Transparent Proxy、高性能、规则分流" "proxy" "https://github.com/sbwml/luci-app-nikki.git"
create_plugin "Momo" "luci-app-momo" "代理工具" "简洁界面、快速连接" "proxy" "https://github.com/sbwml/luci-app-momo.git"
create_plugin "FullCombo" "luci-app-fc" "全能代理" "全能协议、一键配置、智能分流" "proxy" "https://github.com/sbwml/luci-app-fc.git"
create_plugin "Xray" "luci-app-xray" "Xray 代理" "VLESS/Vmess/XTLS/Reality" "proxy" "https://github.com/sbwml/luci-app-xray.git"
create_plugin "NeKoBox" "luci-app-nekobox" "NekoBox 客户端" "Neko 核心、多协议" "proxy" "https://github.com/sbwml/luci-app-nekobox.git"
create_plugin "v2rayA" "luci-app-v2raya" "v2rayA 客户端" "v2ray 核心、Web 管理" "proxy" "https://github.com/v2raya/v2raya.git"
create_plugin "NaiveProxy" "naiveproxy" "代理工具" "轻量代理、HTTPS 传输" "proxy" "https://github.com/sbwml/naiveproxy.git"

echo ""

# ========== 存储管理 (storage) ==========
echo "💾 存储管理:"
create_plugin "DiskMan" "luci-app-diskman" "磁盘管理" "分区管理、格式化、S.M.A.R.T" "storage" "https://github.com/lisaac/luci-app-diskman.git"
create_plugin "Aria2" "luci-app-aria2" "下载工具" "HTTP/FTP/BT 下载" "storage" "https://github.com/sbwml/luci-app-aria2.git"
create_plugin "Qbittorrent" "luci-app-qbittorrent" "BT 下载" "BT/磁力链、RSS 订阅" "storage" "https://github.com/sbwml/luci-app-qbittorrent.git"
create_plugin "Samba4" "luci-app-samba4" "文件共享" "SMB/CIFS 共享" "storage" "https://github.com/sbwml/luci-app-samba4.git"
create_plugin "FileBrowser" "luci-app-filebrowser" "文件管理" "Web 文件管理" "storage" "https://github.com/sbwml/luci-app-filebrowser.git"
create_plugin "WebDAV" "luci-app-webdav" "WebDAV 服务" "WebDAV 协议" "storage" "https://github.com/sbwml/luci-app-webdav.git"
create_plugin "阿里云盘WebDAV" "luci-app-aliyundrive-webdav" "阿里云盘" "阿里云盘集成" "storage" "https://github.com/sbwml/luci-app-aliyundrive-webdav.git"
create_plugin "Clouddrive2" "luci-app-clouddrive2" "多云盘管理" "20+ 云盘支持" "storage" "https://github.com/sbwml/luci-app-clouddrive2.git"
create_plugin "Cloudreve" "luci-app-cloudreve" "私有云盘" "私有云存储" "storage" "https://github.com/sbwml/luci-app-cloudreve.git"
create_plugin "Rclone" "luci-app-rclone" "云盘同步" "50+ 云盘支持" "storage" "https://github.com/sbwml/luci-app-rclone.git"
create_plugin "MiniDLNA" "luci-app-minidlna" "DLNA 媒体服务" "媒体推送" "storage" "https://github.com/sbwml/luci-app-minidlna.git"
create_plugin "Alist" "luci-app-alist" "文件列表" "多存储支持" "storage" "https://github.com/sbwml/luci-app-openlist2.git"
create_plugin "Linkease" "luci-app-linkease" "易有云" "文件管理、远程访问" "storage" "https://github.com/sbwml/luci-app-linkease.git"
create_plugin "KodExplorer" "luci-app-kodexplorer" "可道云网盘" "在线办公" "storage" "https://github.com/sbwml/luci-app-kodexplorer.git"
create_plugin "VSFTPD" "luci-app-vsftpd" "FTP 服务器" "FTP 服务" "storage" "https://github.com/sbwml/luci-app-vsftpd.git"

echo ""

# ========== 网络工具 (network) ==========
echo "🌐 网络工具:"
create_plugin "Tailscale" "luci-app-tailscale-community" "虚拟组网" "异地组网、P2P 直连" "network" "https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community.git"
create_plugin "ZeroTier" "luci-app-zerotier" "内网穿透" "虚拟局域网" "network" "https://github.com/sbwml/luci-app-zerotier.git"
create_plugin "FRPC" "luci-app-frpc" "FRP 客户端" "内网穿透" "network" "https://github.com/sirpdboy/luci-app-frpc.git"
create_plugin "FRPS" "luci-app-frps" "FRP 服务端" "FRP 管理" "network" "https://github.com/sirpdboy/luci-app-frps.git"
create_plugin "DDNS-GO" "luci-app-ddns-go" "动态 DNS" "轻量 DDNS" "network" "https://github.com/sirpdboy/luci-app-ddns-go.git"
create_plugin "MosDNS" "luci-app-mosdns" "DNS 转发" "DNS 分流、去广告" "network" "https://github.com/sbwml/luci-app-mosdns.git"
create_plugin "SmartDNS" "luci-app-smartdns" "智能 DNS" "多上游 DNS" "network" "https://github.com/sbwml/luci-app-smartdns.git"
create_plugin "Lucky" "luci-app-lucky" "多功能工具" "端口转发、DDNS" "network" "https://github.com/sbwml/luci-app-lucky.git"
create_plugin "EasyTier" "luci-app-easytier" "异地组网" "去中心化组网" "network" "https://github.com/EasyTier/luci-app-easytier.git"
create_plugin "DDNSTO" "luci-app-ddnsto" "内网穿透" "免费穿透" "network" "https://github.com/sbwml/luci-app-ddnsto.git"
create_plugin "NATMap" "luci-app-natmap" "端口映射" "自动映射" "network" "https://github.com/sbwml/luci-app-natmap.git"
create_plugin "Socat" "luci-app-socat" "端口转发" "TCP/UDP 转发" "network" "https://github.com/sbwml/luci-app-socat.git"
create_plugin "AdGuardHome" "luci-app-adguardhome" "ADG 去广告" "DNS 去广告" "network" "https://github.com/rufengsuixing/luci-app-adguardhome.git"
create_plugin "AdByBy" "luci-app-adbyby-plus" "去广告" "规则去广告" "network" "https://github.com/sbwml/luci-app-adbyby-plus.git"
create_plugin "DNSFilter" "luci-app-my-dnsfilter" "DNS 去广告" "DNS 过滤" "network" "https://github.com/sbwml/luci-app-my-dnsfilter.git"
create_plugin "OAF" "luci-app-oaf" "应用过滤" "应用识别" "network" "https://github.com/sbwml/luci-app-oaf.git"
create_plugin "BandiX" "luci-app-bandix" "流量监控" "实时流量" "network" "https://github.com/sirpdboy/luci-app-bandix.git"
create_plugin "EqOS" "luci-app-eqosplus" "IP 限速" "按 IP 限速" "network" "https://github.com/sirpdboy/luci-app-eqosplus.git"
create_plugin "FastNet" "luci-app-fastnet" "网络测速" "速度测试" "network" "https://github.com/sirpdboy/luci-app-fastnet.git"
create_plugin "QoS" "luci-app-qosmate" "流量控制" "带宽管理" "network" "https://github.com/sirpdboy/luci-app-qosmate.git"
create_plugin "Netdata" "luci-app-netdata" "性能监测" "实时监控" "network" "https://github.com/sbwml/luci-app-netdata.git"
create_plugin "NPC" "luci-app-npc" "NPS 客户端" "内网穿透" "network" "https://github.com/sbwml/luci-app-npc.git"
create_plugin "IPTV" "luci-app-iptvhelper" "IPTV 助手" "IPTV 组播" "network" "https://github.com/sbwml/luci-app-iptvhelper.git"
create_plugin "EasyMesh" "luci-app-easymesh" "Mesh 组网" "无缝漫游" "network" "https://github.com/sbwml/luci-app-easymesh.git"
create_plugin "TurboACC" "luci-app-turboacc" "网络加速" "硬件加速" "network" "https://github.com/chenmozhijin/luci-app-turboacc.git"
create_plugin "Docker" "luci-app-dockerman" "Docker 管理" "容器管理" "network" "https://github.com/sbwml/luci-app-dockerman.git"
create_plugin "Thunder" "luci-app-thunder" "迅雷下载" "远程下载" "network" "https://github.com/sbwml/luci-app-thunder.git"
create_plugin "OpenList2" "luci-app-openlist2" "文件列表" "原 Alist" "network" "https://github.com/sbwml/luci-app-openlist2.git"
create_plugin "Btop" "btop" "性能监控" "系统监控" "network" "https://github.com/sbwml/btop.git"
create_plugin "NLBWmon" "luci-app-nlbwmon" "流量统计" "按 IP 统计" "network" "https://github.com/jow-/luci-app-nlbwmon.git"
create_plugin "VNT" "luci-app-vnt" "VNT 组网" "异地组网" "network" "https://github.com/lmq8267/luci-app-vnt.git"

echo ""

# ========== 主题 (theme) ==========
echo "🎨 主题:"
create_plugin "Argon" "luci-theme-argon" "流行主题" "毛玻璃效果" "theme" "https://github.com/jerrykuku/luci-theme-argon.git"
create_plugin "Aurora" "luci-theme-aurora" "极光主题" "渐变效果" "theme" "https://github.com/kenzok8/luci-theme-aurora.git"
create_plugin "Kucat" "luci-theme-kucat" "可爱主题" "多彩配色" "theme" "https://github.com/kenzok8/luci-theme-kucat.git"
create_plugin "Material" "luci-theme-material" "Material 设计" "卡片布局" "theme" "https://github.com/kenzok8/luci-theme-material.git"
create_plugin "Material3" "luci-theme-material3" "Material3" "动态主题" "theme" "https://github.com/kenzok8/luci-theme-material3.git"
create_plugin "Design" "luci-theme-design" "Design 主题" "现代界面" "theme" "https://github.com/kenzok8/luci-theme-design.git"
create_plugin "Alpha" "luci-theme-alpha" "Alpha 主题" "简洁风格" "theme" "https://github.com/kenzok8/luci-theme-alpha.git"
create_plugin "Spectra" "luci-theme-spectra" "Spectra" "多彩渐变" "theme" "https://github.com/kenzok8/luci-theme-spectra.git"
create_plugin "Routerich" "luci-theme-routerich" "Routerich" "商务风格" "theme" "https://github.com/kenzok8/luci-theme-routerich.git"
create_plugin "Lightblue" "luci-theme-lightblue" "浅蓝主题" "清爽界面" "theme" "https://github.com/kenzok8/luci-theme-lightblue.git"
create_plugin "Teleofis" "luci-theme-teleofis" "Teleofis" "工业风格" "theme" "https://github.com/kenzok8/luci-theme-teleofis.git"

echo ""

# ========== 系统工具 (system) ==========
echo "🔧 系统工具:"
create_plugin "TTYD" "luci-app-ttyd" "网页终端" "SSH 访问" "system" "https://github.com/sbwml/luci-app-ttyd.git"
create_plugin "Automount" "automount" "自动挂载" "USB 热插拔" "system" "https://github.com/sbwml/automount.git"
create_plugin "HD-Idle" "luci-app-hd-idle" "硬盘休眠" "节能保护" "system" "https://github.com/sbwml/luci-app-hd-idle.git"
create_plugin "PartExp" "luci-app-partexp" "分区扩容" "无损扩容" "system" "https://github.com/sbwml/luci-app-partexp.git"
create_plugin "AccessControl" "luci-app-accesscontrol-plus" "访问控制" "MAC 过滤" "system" "https://github.com/sbwml/luci-app-accesscontrol-plus.git"
create_plugin "ParentControl" "luci-app-parentcontrol" "家长控制" "网站过滤" "system" "https://github.com/sbwml/luci-app-parentcontrol.git"
create_plugin "TimeControl" "luci-app-nft-timecontrol" "上网时间" "定时断网" "system" "https://github.com/sbwml/luci-app-nft-timecontrol.git"
create_plugin "GuestWiFi" "luci-app-guest-wifi" "访客 WiFi" "隔离网络" "system" "https://github.com/sbwml/luci-app-guest-wifi.git"
create_plugin "WiFiSchedule" "luci-app-wifischedule" "WiFi 计划" "定时开关" "system" "https://github.com/sbwml/luci-app-wifischedule.git"
create_plugin "TimedReboot" "luci-app-timedreboot" "定时重启" "自动重启" "system" "https://github.com/sirpdboy/luci-app-timedreboot.git"
create_plugin "Watchcat" "luci-app-watchcat" "断网检测" "自动恢复" "system" "https://github.com/sirpdboy/luci-app-watchcat.git"
create_plugin "TimeWOL" "luci-app-timewol" "网络唤醒" "远程开机" "system" "https://github.com/sirpdboy/luci-app-timewol.git"
create_plugin "ARPBind" "luci-app-arpbind" "ARP 绑定" "IP-MAC 绑定" "system" "https://github.com/sbwml/luci-app-arpbind.git"
create_plugin "HomeAssistant" "luci-app-homeassistant" "智能家居" "设备联动" "system" "https://github.com/sbwml/luci-app-homeassistant.git"
create_plugin "VLMCSD" "luci-app-vlmcsd" "KMS 服务" "激活服务" "system" "https://github.com/sbwml/luci-app-vlmcsd.git"
create_plugin "CUPS" "luci-app-cupsd" "打印服务" "网络打印" "system" "https://github.com/sbwml/luci-app-cupsd.git"
create_plugin "SNMPD" "luci-app-snmpd" "SNMP 监控" "设备管理" "system" "https://github.com/sbwml/luci-app-snmpd.git"
create_plugin "SubConverter" "luci-app-subconverter" "订阅转换" "规则生成" "system" "https://github.com/sbwml/luci-app-subconverter.git"
create_plugin "ACME" "luci-app-acme" "HTTPS 证书" "自动续签" "system" "https://github.com/sbwml/luci-app-acme.git"
create_plugin "AirPlay2" "luci-app-airplay2" "AirPlay2" "音频流" "system" "https://github.com/sbwml/luci-app-airplay2.git"
create_plugin "WeChatPush" "luci-app-wechatpush" "通知推送" "微信/Telegram" "system" "https://github.com/sbwml/luci-app-wechatpush.git"
create_plugin "NeteaseUnlock" "luci-app-unblockneteasemusic" "解锁网易云" "版权解锁" "system" "https://github.com/sbwml/luci-app-unblockneteasemusic.git"
create_plugin "TVHelper" "tvhelper" "盒子助手" "直播源" "system" "https://github.com/sbwml/tvhelper.git"
create_plugin "Store" "luci-app-store" "iStore" "应用商店" "system" "https://github.com/sbwml/luci-app-store.git"
create_plugin "UUGameBooster" "luci-app-uugamebooster" "UU 加速器" "游戏加速" "system" "https://github.com/sbwml/luci-app-uugamebooster.git"
create_plugin "TaskPlan" "luci-app-taskplan" "定时任务" "计划执行" "system" "https://github.com/sirpdboy/luci-app-taskplan.git"
create_plugin "SQM" "luci-app-sqm-autorate" "SQM QoS" "智能队列" "system" "https://github.com/sbwml/luci-app-sqm-autorate.git"

echo ""
echo "=========================================="
echo "✅ 共生成 $(ls -d $PLUGINS_DIR/*/ | wc -l) 个插件目录"
echo "=========================================="
