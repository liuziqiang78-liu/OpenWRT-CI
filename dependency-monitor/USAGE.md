# OpenWRT-CI 依赖监控工具

本仓库包含完整的依赖仓库监控解决方案，帮助你跟踪所有外部依赖的健康状态。

---

## 📁 文件结构

```
OpenWRT-CI/
├── .github/workflows/
│   └── Dependency-Monitor.yml    # GitHub Actions 定时监控 (每天运行)
├── Scripts/
│   └── dependency-monitor.sh     # 本地监控脚本
└── dependency-monitor/
    ├── README.md                 # 当前监控报告
    ├── results.csv               # CSV 格式结果
    └── report.md                 # Markdown 报告
```

---

## 🔧 使用方法

### 方法 1: GitHub Actions 自动监控 (推荐)

1. 推送仓库到 GitHub
2. 工作流会**每天早上 8 点**自动运行
3. 发现问题时会自动创建 Issue
4. 报告保存在 Artifacts 中

**手动触发**:
- 进入 Actions → Dependency Monitor → Run workflow

### 方法 2: 本地运行脚本

```bash
cd OpenWRT-CI
bash Scripts/dependency-monitor.sh
```

输出目录：`dependency-monitor/`

---

## 📊 监控内容

### 检查项目
- ✅ 仓库是否存在
- ✅ 分支是否可用
- ✅ 仓库是否被归档
- ✅ 最后提交时间
- ⭐ Star 数量
- 🍴 Fork 数量

### 状态说明
| 状态 | 说明 |
|------|------|
| ✅ HEALTHY | 正常，最近 180 天内有更新 |
| ⚠️ OLD | 较旧，180-365 天无更新 |
| ⚠️ STALE | 过时，超过 365 天无更新 |
| ⚠️ ARCHIVED | 仓库已被作者归档 |
| ❌ NOT FOUND | 仓库不存在 |
| ❌ BRANCH NOT FOUND | 分支不存在 |
| ❌ API ERROR | API 调用失败 |

---

## 📦 监控的依赖 (32 个)

### 核心源码 (2 个)
- immortalwrt/immortalwrt
- VIKINGYFY/immortalwrt

### 代理插件 (6 个)
- OpenClash, PassWall, PassWall2, HomeProxy, Nikki, Momo

### 主题 (5 个)
- Argon, Aurora, Kucat 及配置插件

### 网络工具 (5 个)
- Tailscale, DDNS-GO, EasyTier, VNT, Lucky

### 存储工具 (5 个)
- DiskMan, Qbittorrent, OpenList2, QuickFile, PartExp

### 系统工具 (6 个)
- FanControl, MosDNS, NetSpeedTest, QModem, Viking, Gecoosac

### U-Boot (3 个)
- IPQ60XX EMMC/NAND/NOR U-Boot

---

## ⚠️ 风险提示

### 单一作者依赖
多个插件依赖以下作者，存在集中风险：
- **sirpdboy** (6 个插件)
- **sbwml** (5 个插件)
- **VIKINGYFY** (3 个插件)

### 建议
1. 定期运行监控脚本
2. 关注警告状态的仓库
3. 对关键插件准备备份源
4. 重要插件可考虑 fork 到本地

---

## 🔗 相关链接

- GitHub 仓库：https://github.com/liuziqiang78-liu/OpenWRT-CI
- ImmortalWRT: https://github.com/immortalwrt/immortalwrt
- ClawHub 技能：已安装 GitHub 相关技能

---

*最后更新：2026-04-11*
