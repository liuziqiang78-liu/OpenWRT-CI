# OpenWRT-CI 依赖仓库监控报告

**生成时间**: 2026-04-11 12:55
**监控方式**: GitHub 页面可访问性检查

---

## 📊 核心依赖状态

| 类别 | 仓库 | 状态 | 说明 |
|------|------|------|------|
| **源码** | VIKINGYFY/immortalwrt | ✅ 可访问 | 主要源码 (高通版) |
| **源码** | immortalwrt/immortalwrt | ✅ 可访问 | 官方 ImmortalWRT |
| **代理** | vernesong/OpenClash | ✅ 可访问 | Clash 客户端 |
| **代理** | Openwrt-Passwall/openwrt-passwall | ✅ 可访问 | PassWall 代理 |
| **代理** | Openwrt-Passwall/openwrt-passwall2 | ⏳ 待检查 | PassWall2 |
| **代理** | VIKINGYFY/homeproxy | ⏳ 待检查 | HomeProxy |
| **主题** | sbwml/luci-theme-argon | ✅ 可访问 | Argon 主题 |
| **主题** | eamonxg/luci-theme-aurora | ⏳ 待检查 | Aurora 主题 |
| **主题** | sirpdboy/luci-theme-kucat | ⏳ 待检查 | Kucat 主题 |

---

## 📦 完整依赖清单

### 主题类 (5 个)
- sbwml/luci-theme-argon (分支：openwrt-25.12)
- eamonxg/luci-theme-aurora (分支：master)
- eamonxg/luci-app-aurora-config (分支：master)
- sirpdboy/luci-theme-kucat (分支：master)
- sirpdboy/luci-app-kucat-config (分支：master)

### 代理类 (6 个)
- VIKINGYFY/homeproxy (分支：main)
- vernesong/OpenClash (分支：dev)
- Openwrt-Passwall/openwrt-passwall (分支：main)
- Openwrt-Passwall/openwrt-passwall2 (分支：main)
- nikkinikki-org/OpenWrt-nikki (分支：main)
- nikkinikki-org/OpenWrt-momo (分支：main)

### 网络工具 (5 个)
- Tokisaki-Galaxy/luci-app-tailscale-community (分支：master)
- sirpdboy/luci-app-ddns-go (分支：main)
- EasyTier/luci-app-easytier (分支：main)
- lmq8267/luci-app-vnt (分支：main)
- sirpdboy/luci-app-lucky (分支：main)

### 存储工具 (5 个)
- lisaac/luci-app-diskman (分支：master)
- sbwml/luci-app-qbittorrent (分支：master)
- sbwml/luci-app-openlist2 (分支：main)
- sbwml/luci-app-quickfile (分支：main)
- sirpdboy/luci-app-partexp (分支：main)

### 系统工具 (6 个)
- rockjake/luci-app-fancontrol (分支：main)
- sbwml/luci-app-mosdns (分支：v5)
- sirpdboy/luci-app-netspeedtest (分支：main)
- FUjr/QModem (分支：main)
- VIKINGYFY/packages (分支：main)
- laipeng668/luci-app-gecoosac (分支：main)

### U-Boot (3 个)
- chenxin527/uboot-ipq60xx-emmc-build (分支：main)
- chenxin527/uboot-ipq60xx-nand-build (分支：main)
- chenxin527/uboot-ipq60xx-nor-build (分支：main)

---

## ⚠️ 风险提示

### 高风险依赖
1. **单一来源依赖** - 多个插件依赖同一作者 (sirpdboy, sbwml)
2. **第三方源码** - 依赖 VIKINGYFY/immortalwrt 而非官方

### 建议措施
1. 定期备份关键插件的 Makefile
2. 监控主要依赖仓库的活跃度
3. 准备备用源码和插件源

---

## 🔧 监控脚本

已创建监控脚本：`Scripts/dependency-monitor.sh`

使用方法：
```bash
cd OpenWRT-CI
bash Scripts/dependency-monitor.sh
```

输出目录：`dependency-monitor/`
- `results.csv` - CSV 格式结果
- `report.md` - Markdown 报告

---

*报告由 OpenWRT-CI 依赖监控系统生成*
