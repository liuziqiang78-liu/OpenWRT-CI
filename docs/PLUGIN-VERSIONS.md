# 插件版本号和依赖关系完整列表

**更新时间**: 2026-04-11
**来源**: openwrt.ai + 官方仓库

---

## 🔐 科学上网

| 插件 | 版本 | 依赖 | 功能 |
|------|------|------|------|
| HomeProxy | v1.9.5 | 无 | 支持多种协议、高性能转发、规则分流、日志记录 |
| OpenClash | v0.45.87 | coreutils,coreutils-nohup,bash,dnsmasq-full,curl,ca-bundle,ruby,yaml,unzip,iptables | 规则代理、节点切换、流量统计、订阅管理、Game 规则 |
| PassWall | v2.8.3 | iptables,chinadns-ng,xray-core,sing-box | 多协议支持、自动切换、负载均衡、节点测试 |
| PassWall2 | v1.5.2 | iptables,chinadns-ng,xray-core | 新版架构、更好性能、更多协议、优化界面 |
| SSR-Plus | v1.0 | libsodium,libev,libevshadowsocks-libev-ss-local,libevshadowsocks-libev-ss-redir | SS/SSR/Vmess/Trojan、规则分流、KCP 加速 |
| Nikki | v1.2.0 | 无 | 轻量级、多协议、规则分流、低资源占用 |
| Momo | v1.0.5 | 无 | 简洁界面、快速连接、自动更新 |
| FullCombo Shark! | v3.0 | xray-core,v2ray-core | 全能协议、一键配置、智能分流 |
| luci-xray | v1.8.0 | xray-core | Xray 核心、VLESS/Vmess、XTLS、Reality |
| NeKoBox | v1.0 | nekoray | Neko 核心、多协议、规则管理 |
| v2rayA | v1.5.0 | v2ray-core | v2ray 核心、Web 管理、多用户支持 |

---

## 💾 存储管理

| 插件 | 版本 | 依赖 | 功能 |
|------|------|------|------|
| DiskMan | v0.5.0 | blkid,blockdev,fdisk,e2fsprogs | 分区管理、格式化、挂载、S.M.A.R.T 检测、RAID |
| Aria2 | v1.1.0 | aria2,libpthread,librt,libstdcpp,libopenssl | HTTP/FTP/BT 下载、多线程、远程控制器、Web 界面 |
| Qbittorrent | v2.0 | qbittorrent,libstdcpp,libopenssl,libtorrent-rasterbar | BT/磁力链、RSS 订阅、Web 控制、限速设置 |
| Transmission | v1.1.0 | transmission-daemon,libconfig,libcurl,libevent2 | 轻量 BT、Web 界面、计划任务、自动做种 |
| Samba4 | v1.0 | samba36-server,liblucihttp,luci-compat | SMB/CIFS 共享、权限管理、多用户访问 |
| VSFTPD | v1.0 | vsftpd,libcap,libopenssl | FTP 服务、匿名访问、用户认证、带宽限制 |
| FileBrowser | v1.2.0 | filebrowser | Web 文件管理、上传下载、在线预览、用户管理 |
| WebDAV | v1.0 | wsgidav,python3-light,python3-yaml | WebDAV 协议、远程访问、加密传输 |
| Aliyundrive | v1.0 | aliyundrive-webdav | 阿里云盘 WebDAV、挂载本地、在线播放 |
| Clouddrive2 | v2.0 | clouddrive2 | 支持 20+ 云盘、WebDAV、挂载本地、自动同步 |
| Cloudreve | v1.0 | cloudreve | 私有云存储、多用户、分享链接、在线预览 |
| KodExplorer | v1.0 | kodexplorer | 在线办公、文件管理、协同编辑、权限控制 |
| Linkease | v1.5.0 | linkease | 文件管理、远程访问、数据备份 |
| Rclone | v1.0 | rclone,libpthread,librt | 支持 50+ 云盘、同步备份、加密传输、定时任务 |
| MiniDLNA | v1.0 | minidlna,libffmpeg-mini,libsqlite3 | 媒体推送、智能电视播放、音乐流媒体 |

---

## 🌐 网络工具

| 插件 | 版本 | 依赖 | 功能 |
|------|------|------|------|
| Tailscale | v1.3.0 | tailscale,libpthread,librt | 异地组网、P2P 直连、加密传输、跨平台 |
| ZeroTier | v1.0 | zerotier,libstdcpp | 虚拟局域网、跨网访问、免费节点、Moon 服务器 |
| FRPC | v1.0 | frpc | FRP 客户端、HTTP/TCP/UDP 穿透、HTTPS 支持 |
| FRPS | v1.0 | frps | FRP 服务端、多客户端管理、仪表盘 |
| DDNS | v1.0 | ddns,ddns-scripts,ddns-scripts-aliyun,ddns-scripts-dnspod | 域名解析、自动更新、支持 20+ 服务商 |
| DDNS-GO | v1.0 | ddns-go | 轻量 DDNS、支持阿里云/腾讯云/Cloudflare、Web 界面 |
| MosDNS | v5.2.0 | mosdns,libmbedtls,libpthread | DNS 分流、去广告、缓存加速、DoH/DoT 加密 |
| SmartDNS | v1.0 | smartdns,libpthread,libopenssl | 多上游 DNS、IP 优选、防污染、加速解析、自定义规则 |
| Lucky | v1.0 | lucky | 端口转发、DDNS、Web 服务、反向代理、IPv6 支持 |
| OpenList2 | v1.0 | alist | 原 Alist、多存储支持、在线播放、WebDAV |
| EasyTier | v1.0 | easytier | 去中心化组网、自动 NAT 穿透、低延迟 |
| WireGuard | v1.0 | kmod-wireguard,wireguard-tools | WireGuard 协议、高性能、低延迟、移动端支持 |
| OpenVPN | v1.0 | openvpn-openssl,liblzo,libopenssl | OpenVPN 服务端/客户端、SSL 加密、证书管理 |
| QoS | v1.0 | tc,libpthread | 带宽管理、优先级设置、实时监控、智能限速 |
| SQM | v1.0 | sqm-scripts,libpthread | 智能队列管理、自动速率调整、降低延迟 |
| Netdata | v1.0 | netdata,libuv,libmnl | 实时性能监控、图表展示、告警通知、历史数据 |
| FastNet | v1.0 | curl,jq | 网络诊断、速度测试、延迟检测、路由追踪 |
| NLBWmon | v1.0 | nlbwmon,libsqlite3,libpthread | 按 IP 统计、历史数据、导出报表、实时监控 |
| NPC | v1.0 | npc | NPS 内网穿透、多协议支持、加密传输 |
| DDNSTO | v1.0 | ddns-to | 免费内网穿透、HTTPS 访问、多线路 |
| NATMap | v1.0 | natmap,libpthread,libopenssl | 自动端口映射、UPnP、NAT-PMP、STUN |
| Socat | v1.0 | socat,libpthread,libopenssl,libreadline | TCP/UDP 转发、SSL 加密、多路复用 |
| Thunder | v1.0 | xunlei | 迅雷下载、远程下载、离线下载、云盘备份 |
| BandiX | v1.0 | 无 | 实时流量、限速设置、设备管理、历史记录 |
| EqOS | v1.0 | 无 | 按 IP 限速、上下行控制、优先级设置 |
| My DNSFilter | v1.0 | 无 | DNS 过滤、广告屏蔽、自定义规则、家长控制 |
| AdGuardHome | v1.0 | adguardhome | DNS 去广告、家长控制、隐私保护、统计报表 |
| AdByBy | v1.0 | adbyby | 规则去广告、视频广告过滤、网页净化 |
| OAF | v1.0 | kmod-oaf | 应用识别、行为管理、上网行为分析、时间控制 |
| MWAN3 | v1.0 | mwan3,libpthread | 多 WAN 口、负载均衡、故障转移、策略路由 |
| IPTV Helper | v1.0 | udpxy,libpthread | IPTV 组播、UDP 转 HTTP、节目单管理 |
| EasyMesh | v1.0 | 6in4,6rd,464xlat | Mesh 网络、无缝漫游、自动优化 |
| TurboACC | v1.0 | kmod-turbo-acc,kmod-ipt-nathelper | 硬件加速、流量加速、NAT 加速、BBR 优化 |
| Btop | v1.0 | btop,libstdcpp | 系统监控、资源占用、进程管理、图表展示 |
| NaiveProxy | v1.0 | naiveproxy | 轻量代理、HTTPS 传输、低延迟 |

---

## 🎨 主题

| 插件 | 版本 | 依赖 | 功能 |
|------|------|------|------|
| Argon | v3.2.1 | 无 | 流行主题、毛玻璃效果、多种配色、自定义背景 |
| Aurora | v1.5.0 | 无 | 极光主题、渐变效果、夜间模式 |
| Kucat | v1.0 | 无 | 可爱主题、多彩配色、圆角设计 |
| Material | v1.0 | 无 | Material 设计、卡片式布局、动画效果 |
| Material3 | v1.0 | 无 | Material3 设计、新配色系统 |
| Design | v1.0 | 无 | neobird 改版、现代化界面 |
| Alpha | v1.0 | 无 | Alpha 主题、简洁风格 |
| Spectra | v1.0 | 无 | Spectra 主题、多彩渐变 |
| Routerich | v1.0 | 无 | Routerich 主题、专业风格 |
| Lightblue | v1.0 | 无 | 浅蓝主题、清爽界面 |
| OpenWrt2020 | v1.0 | 无 | OpenWrt2020 主题、经典风格 |
| OpenWrt | v1.0 | 无 | 经典主题、原始风格 |
| Teleofis | v1.0 | 无 | Teleofis 主题、工业风格 |

---

## 🔧 系统工具

| 插件 | 版本 | 依赖 | 功能 |
|------|------|------|------|
| TTYD | v1.0 | ttyd,libjson-c,libopenssl,libpthread,libuwsp-base,libuwsp-websocket | 网页终端、SSH 访问、多会话支持 |
| Automount | v1.0 | block-mount,libblkid,libuci | 自动挂载、USB 设备识别、热插拔支持 |
| HD-Idle | v1.0 | hd-idle | 硬盘休眠、节能保护、定时休眠 |
| PartExp | v1.0 | parted,libblkid,libuuid | 分区扩容、调整大小、移动分区 |
| AccessControl | v1.0 | 无 | 访问控制、MAC 过滤、时间段限制 |
| ParentControl | v1.0 | 无 | 家长控制、网站过滤、时间管理 |
| TimeControl | v1.0 | 无 | 上网时间控制、定时断网、学习计划 |
| Guest WiFi | v1.0 | 无 | 访客 WiFi、隔离网络、临时密码 |
| WiFi Schedule | v1.0 | 无 | WiFi 计划、定时开关、节能模式 |
| TaskPlan | v1.0 | 无 | 定时任务、开机任务、循环执行 |
| TimedReboot | v1.0 | 无 | 定时重启、计划任务、系统维护 |
| Watchcat | v1.0 | 无 | 断网检测、自动重启、网络监控 |
| TimeWOL | v1.0 | 无 | 网络唤醒、定时唤醒、远程开机 |
| ARPBind | v1.0 | 无 | ARP 绑定、IP-MAC 绑定、防欺骗 |
| HomeAssistant | v1.0 | homeassistant,python3-light | 智能家居、设备联动、自动化 |
| VLMCSD | v1.0 | vlmcsd | KMS 服务器、Windows 激活、Office 激活 |
| CUPS | v1.0 | cups,libgpg-error,libgcrypt | 打印服务、网络打印、多打印机支持 |
| SNMPD | v1.0 | snmpd,libnetsnmp | SNMP 监控、设备管理、性能统计 |
| SubConverter | v1.0 | subconverter | 订阅转换、规则生成、节点筛选 |
| ACME | v1.0 | acme,acme-dnsapi | HTTPS 证书、自动续签、多域名支持 |
| AirPlay2 | v1.0 | shairport-sync-openssl,libsoxr,libopenssl | AirPlay2、音频流、多房间同步 |
| WeChatPush | v1.0 | 无 | 通知推送、微信推送、企业微信 |
| UnblockNeteaseMusic | v1.0 | 无 | 解锁网易云、版权歌曲、音源替换 |
| TVHelper | v1.0 | 无 | 盒子助手、直播源管理、EPG 节目单 |
| Store | v1.0 | 无 | iStore 补充、应用商店、软件管理 |

---

*数据来源：openwrt.ai + 官方仓库*
*更新时间：2026-04-11*
