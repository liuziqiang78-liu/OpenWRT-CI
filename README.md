# OpenWRT-CI - 云编译 OpenWRT 固件

[![Build Status](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions/workflows/Custom-Build.yml/badge.svg)](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions)

---

## 🚀 快速开始

### 方式一：GitHub Actions 在线编译

1. 访问 [Actions](https://github.com/liuziqiang78-liu/OpenWRT-CI/actions)
2. 点击 **Custom Build** → **Run workflow**
3. 选择平台、设备、源码、插件 → 开始编译
4. 编译完成后在 [Releases](https://github.com/liuziqiang78-liu/OpenWRT-CI/releases) 下载固件

### 方式二：本地编译

```bash
# 拉取 OpenWRT 源码
git clone https://github.com/immortalwrt/immortalwrt.git
cd immortalwrt

# 安装插件
bash /path/to/OpenWRT-CI/scripts/install-plugins.sh

# 应用配置
cat /path/to/OpenWRT-CI/Config/MEDIATEK.txt >> .config
cat /path/to/OpenWRT-CI/Config/GENERAL.txt >> .config

# 编译
make -j$(nproc) defconfig && make -j$(nproc)
```

📖 **详细指南**: [QUICK-START.md](QUICK-START.md)

---

## ✨ 特性

- ✅ **自动编译**: GitHub Actions 一键编译
- ✅ **多平台**: MEDIATEK / ROCKCHIP / X86 / QUALCOMMAX
- ✅ **插件管理**: 50+ 插件版本集中管理，自动从 GitHub 拉取
- ✅ **模块化配置**: 按平台 + 设备 + 功能自由组合
- ✅ **自动发布**: 编译完成自动上传 GitHub Releases
- ✅ **UPnP 内置**: 所有固件默认包含 UPnP (iptables 后端)

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
- 通用 x86_64 平台 (PC/笔记本/虚拟机)

### QUALCOMMAX (高通)
- IPQ50XX / IPQ60XX / IPQ807X
- 红米 AX5 / AX6
- 小米 AX3600 / AX9000

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

## 🛠️ 脚本说明

### 核心构建脚本 (CI 使用)

| 脚本 | 作用 |
|------|------|
| `Scripts/Packages.sh` | 安装和更新第三方插件 |
| `Scripts/Handles.sh` | 编译后处理和兼容性修复 |
| `Scripts/Settings.sh` | 注入默认配置到 .config |
| `Scripts/sources/apply-settings.sh` | 按源码类型分发配置 |

### 辅助工具脚本

| 脚本 | 作用 |
|------|------|
| `scripts/install-plugins.sh` | 本地安装插件 |
| `scripts/generate-plugins.sh` | 生成插件配置 |
| `scripts/verify-mappings.py` | 验证插件映射完整性 |
| `scripts/find-plugin-repos.py` | 自动查找插件 GitHub 仓库 |

---

## 📥 下载固件

- **最新固件**: [Releases](https://github.com/liuziqiang78-liu/OpenWRT-CI/releases/latest)
- **所有版本**: [Releases History](https://github.com/liuziqiang78-liu/OpenWRT-CI/releases)

---

## 📚 文档

- [QUICK-START.md](QUICK-START.md) - 快速开始指南
- [CHANGELOG.md](CHANGELOG.md) - 更新日志
- [LINKS.md](LINKS.md) - 相关链接

---

## 🔗 相关资源

- [ImmortalWRT](https://github.com/immortalwrt/immortalwrt)
- [OpenWRT](https://github.com/openwrt/openwrt)

---

## 📄 许可证

MIT License

---

## 🙏 致谢

- [ImmortalWRT](https://github.com/immortalwrt/immortalwrt)
- [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI)
- 所有插件作者
