# OpenWRT-CI - 云编译 OpenWRT 固件

[![Build Status](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions/workflows/OWRT-ALL.yml/badge.svg)](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions)
[![Dependency Monitor](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions/workflows/Dependency-Monitor.yml/badge.svg)](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions/workflows/Dependency-Monitor.yml)
[![Plugin Version Check](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions/workflows/Plugin-Version-Check.yml/badge.svg)](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions/workflows/Plugin-Version-Check.yml)

---

## 🚀 快速开始 (3 分钟完成配置)

### 最简单的方式

```bash
cd OpenWRT-CI
bash Scripts/one-click.sh
```

**按提示选择即可！**

---

### 交互式配置向导

```bash
bash Scripts/config-wizard.sh
```

**步骤**:
1. 选择平台 (MEDIATEK/ROCKCHIP/X86/QUALCOMMAX)
2. 选择设备 (小米/360/NanoPi 等)
3. 选择功能 (基础/科学/广告/NAS/游戏/全部)
4. 自动生成配置

---

### 常用配置速查

```bash
# 小米 AX3000T - 科学上网
bash Scripts/config-builder.sh MEDIATEK xiaomi_ax3000t proxy

# NanoPi R4S - 旁路由
bash Scripts/config-builder.sh ROCKCHIP nanopi_r4s proxy network-extra

# X86 - All in One
bash Scripts/config-builder.sh X86 generic full

# 360 T7 - 广告过滤
bash Scripts/config-builder.sh MEDIATEK 360_t7 adblock
```

📖 **详细指南**: [QUICK-START.md](QUICK-START.md)

---

## ✨ 特性

- ✅ **自动编译**: 每天 4:00 AM 定时编译
- ✅ **版本控制**: 32+ 插件版本集中管理
- ✅ **依赖监控**: 自动检查 32 个依赖仓库健康状态
- ✅ **多平台**: MEDIATEK / ROCKCHIP / X86 / QUALCOMMAX
- ✅ **模块化配置**: 自由组合所需功能
- ✅ **自动发布**: 编译完成自动上传 GitHub Releases
- ✅ **失败通知**: 编译失败自动创建 Issue

---

## 📱 支持设备

### MEDIATEK (联发科)
- 小米 AX3000T / WR30U / Redmi AX6000
- 360 T7
- 京东云 RE-CP-03
- 华硕 TUF-AX4200 / AX6000

### ROCKCHIP (瑞芯微)
- NanoPi R2S / R4S / R5S / R6S
- 香橙派 OrangePi 5
- 飞牛 Fastrhino R66S/R68S

### X86
- 通用 x86_64 平台
- PC/笔记本/虚拟机

### QUALCOMMAX (高通)
- IPQ50XX / IPQ60XX / IPQ807X
- 红米 AX5 / AX6
- 小米 AX3600 / AX9000

📖 **完整列表**: [docs/DEVICE-COMPATIBILITY.md](docs/DEVICE-COMPATIBILITY.md)

---

## 🔧 默认配置

| 项目 | 值 |
|------|-----|
| IP 地址 | 192.168.10.1 |
| 用户名 | root |
| 密码 | 无 |
| WiFi 名称 | OWRT |
| WiFi 密码 | 12345678 |

---

## 🛠️ 工具脚本

### 配置工具
```bash
# 一键部署 (推荐)
bash Scripts/one-click.sh

# 交互式向导
bash Scripts/config-wizard.sh

# 手动组合
bash Scripts/config-builder.sh <平台> <设备> [功能...]

# 配置预览
bash Scripts/config-preview.sh

# 配置验证
bash Scripts/validate-config.sh
```

### 版本管理
```bash
# 检查可更新插件
bash Scripts/version-check.sh

# 更新插件版本
bash Scripts/version-update.sh --mode fixed
```

### 监控工具
```bash
# 依赖健康检查
bash Scripts/dependency-monitor.sh

# 配置对比
bash Scripts/config-diff.sh MEDIATEK ROCKCHIP
```

---

## 📊 编译状态

| 平台 | 状态 | 最近编译 |
|------|------|----------|
| MEDIATEK | ✅ | [查看](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions) |
| ROCKCHIP | ✅ | [查看](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions) |
| X86 | ✅ | [查看](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions) |
| QUALCOMMAX | ✅ | [查看](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions) |

---

## 📥 下载固件

1. **最新固件**: [Releases](https://github.com/liuziqiang78-liu/OpenWRT-CI/releases/latest)
2. **所有版本**: [Releases History](https://github.com/liuziqiang78-liu/OpenWRT-CI/releases)
3. **校验固件**: 下载后验证 SHA256/MD5

---

## 📚 文档

### 快速开始
- [QUICK-START.md](QUICK-START.md) - 3 分钟完成配置
- [LINKS.md](LINKS.md) - 快速链接

### 技术文档
- [docs/CONFIG-MODULAR.md](docs/CONFIG-MODULAR.md) - 配置模块化指南
- [docs/VERSION-CONTROL.md](docs/VERSION-CONTROL.md) - 版本控制指南
- [docs/FIRMWARE-NAMING.md](docs/FIRMWARE-NAMING.md) - 固件命名规范
- [CHANGELOG.md](CHANGELOG.md) - 更新日志

### 优化建议
- [OPTIMIZATION-PROPOSAL.md](OPTIMIZATION-PROPOSAL.md) - 优化建议
- [ADVANCED-OPTIMIZATIONS.md](ADVANCED-OPTIMIZATIONS.md) - 进阶优化
- [IMPROVEMENT-SUMMARY.md](IMPROVEMENT-SUMMARY.md) - 改进总结

---

## 🔗 相关资源

- [ImmortalWRT](https://github.com/immortalwrt/immortalwrt)
- [OpenWRT](https://github.com/openwrt/openwrt)
- [ClawHub](https://clawhub.com)

---

## 📄 许可证

MIT License

---

## 🙏 致谢

- [ImmortalWRT](https://github.com/immortalwrt/immortalwrt)
- [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI)
- 所有插件作者

---

*最后更新：2026-04-11*
