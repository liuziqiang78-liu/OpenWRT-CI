# 🚀 快速开始

---

## 方式一：GitHub Actions 在线编译（推荐）

### 步骤

1. **Fork 本仓库** 到你的 GitHub 账号
2. 访问 **Actions** → **Custom Build** → **Run workflow**
3. 选择参数：
   - **OpenWRT 源码**: immortalwrt / VIKINGYFY / LiBwrt / qosmio
   - **源码分支**: main / owrt / main-nss / 25.12-nss
   - **目标平台**: MEDIATEK / ROCKCHIP / X86 / IPQ50XX / IPQ60XX / IPQ807X
   - **目标设备**: 留空编译全部，填写设备名只编译该设备
   - **插件**: 按需填写（逗号分隔）
   - **主题**: argon / aurora / kucat / alpha / design / material3
4. 等待编译完成（首次 2-3 小时，有缓存后 30-60 分钟）
5. 在 **Releases** 下载固件

### 插件示例

```
科学上网: homeproxy,openclash,passwall
存储管理: diskman,samba4,aria2,qbittorrent
网络工具: tailscale,ddns-go,easytier,vnt
```

---

## 方式二：本地编译

### 前置条件

- Linux 环境 (Ubuntu/Debian 推荐)
- 至少 30GB 磁盘空间
- 已安装编译依赖：`build-essential clang flex g++ gawk gcc-multilib gettext git libncurses5-dev libssl-dev python3-setuptools python3-dev rsync unzip zlib1g-dev`

### 步骤

```bash
# 1. 拉取 OpenWRT 源码
git clone https://github.com/immortalwrt/immortalwrt.git
cd immortalwrt

# 2. 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 3. 安装插件
bash /path/to/OpenWRT-CI/scripts/install-plugins.sh

# 4. 应用平台配置 + 通用配置
cat /path/to/OpenWRT-CI/Config/MEDIATEK.txt >> .config
cat /path/to/OpenWRT-CI/Config/GENERAL.txt >> .config

# 5. 编译
make -j$(nproc) defconfig
make -j$(nproc) download
make -j$(nproc)
```

### 配置文件说明

| 文件 | 作用 |
|------|------|
| `Config/MEDIATEK.txt` | 联发科平台基础配置 |
| `Config/ROCKCHIP.txt` | 瑞芯微平台基础配置 |
| `Config/X86.txt` | x86 平台基础配置 |
| `Config/IPQ*.txt` | 高通平台基础配置 |
| `Config/GENERAL.txt` | 通用配置（所有平台共享） |
| `Config/device/*/device.conf` | 设备特定配置 |
| `Config/device/*/plugins.txt` | 设备专属插件 |

---

## 默认配置

| 项目 | 值 |
|------|-----|
| IP 地址 | 192.168.10.1 |
| 用户名 | root |
| 密码 | 无 |
| WiFi 名称 | OWRT |
| WiFi 密码 | 12345678 |

---

## ❓ 常见问题

### Q: 编译需要多久？
**A**: 首次约 2-3 小时，使用 GitHub Actions 缓存后约 30-60 分钟

### Q: 固件支持哪些设备？
**A**: 查看 `Config/device/` 目录，每个子目录对应一个支持的设备

### Q: 如何只编译某个设备？
**A**: 在 Actions 参数的 **目标设备** 中填写设备目录名（如 `xiaomi_ax3000t`）

---

*最后更新：2026-04-22*
