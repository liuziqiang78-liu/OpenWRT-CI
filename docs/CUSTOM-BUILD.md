# 自定义构建指南

---

## 🎯 功能说明

通过 **Custom Build** 工作流，你可以在编译 OpenWRT 时：

1. ✅ **选择 OpenWRT 源码** (immortalwrt/VIKINGYFY/其他)
2. ✅ **选择源码分支** (main/owrt/master 等)
3. ✅ **选择目标平台** (MEDIATEK/ROCKCHIP/X86 等)
4. ✅ **选择科学上网插件** (OpenClash/PassWall/HomeProxy)
5. ✅ **指定插件版本** (固定版本或使用最新)
6. ✅ **选择存储插件** (DiskMan/Samba/Aria2 等)
7. ✅ **选择网络工具** (Tailscale/DDNS-GO/EasyTier 等)
8. ✅ **选择 UI 主题** (Argon/Aurora/Kucat)
9. ✅ **添加其他插件** (自定义插件)

---

## 🚀 使用方法

### 方法 1: GitHub Actions 界面 (推荐)

1. **访问**: https://github.com/liuziqiang78-liu/OpenWRT-CI/actions
2. **选择**: **Custom Build** 工作流
3. **点击**: **Run workflow**
4. **填写配置**:

```
╔══════════════════════════════════════════╗
║   Custom Build 配置                      ║
╠══════════════════════════════════════════╣
║ OpenWRT 源码：VIKINGYFY/immortalwrt      ║
║ 源码分支：main                           ║
║ 目标平台：MEDIATEK                       ║
║                                           ║
║ 科学上网插件：homeproxy,openclash        ║
║ 插件版本：v1.9.5,v0.45.87                ║
║                                           ║
║ 存储插件：diskman,samba4,aria2           ║
║ 网络工具：tailscale,ddns-go              ║
║                                           ║
║ UI 主题：argon                            ║
║ 其他插件：luci-app-vnt,lucky             ║
║                                           ║
║ 仅输出配置：☐                             ║
╚══════════════════════════════════════════╝
```

5. **点击**: **Run workflow**
6. **等待编译完成** (约 30-60 分钟)
7. **下载固件**: Releases 页面

---

### 方法 2: 使用脚本工具

```bash
# 克隆 OpenWRT 源码
git clone https://github.com/VIKINGYFY/immortalwrt.git wrt
cd wrt

# 安装插件 (指定版本)
bash ../Scripts/install-plugin.sh openclash v0.45.87
bash ../Scripts/install-plugin.sh passwall v2.8.3
bash ../Scripts/install-plugin.sh homeproxy v1.9.5

# 安装插件 (最新版本)
bash ../Scripts/install-plugin.sh diskman
bash ../Scripts/install-plugin.sh tailscale

# 安装主题
bash ../Scripts/install-plugin.sh argon

# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 生成配置
make defconfig

# 编译固件
make -j$(nproc)
```

---

## 📋 支持的插件

### 科学上网类

| 插件名 | 仓库 | 推荐版本 |
|--------|------|----------|
| **openclash** | vernesong/OpenClash | v0.45.87 |
| **passwall** | Openwrt-Passwall/openwrt-passwall | v2.8.3 |
| **passwall2** | Openwrt-Passwall/openwrt-passwall2 | v1.5.2 |
| **homeproxy** | VIKINGYFY/homeproxy | v1.9.5 |

### 存储管理类

| 插件名 | 仓库 | 推荐版本 |
|--------|------|----------|
| **diskman** | lisaac/luci-app-diskman | v0.5.0 |
| **samba4** | 内置 | - |
| **aria2** | sbwml/luci-app-aria2 | 最新 |
| **qbittorrent** | sbwml/luci-app-qbittorrent | 最新 |

### 网络工具类

| 插件名 | 仓库 | 推荐版本 |
|--------|------|----------|
| **tailscale** | Tokisaki-Galaxy/luci-app-tailscale-community | 最新 |
| **ddns-go** | sirpdboy/luci-app-ddns-go | 最新 |
| **easytier** | EasyTier/luci-app-easytier | 最新 |
| **vnt** | lmq8267/luci-app-vnt | 最新 |

### UI 主题类

| 主题名 | 仓库 | 推荐版本 |
|--------|------|----------|
| **argon** | sbwml/luci-theme-argon | v3.2.1 |
| **aurora** | eamonxg/luci-theme-aurora | v1.5.0 |
| **kucat** | sirpdboy/luci-theme-kucat | 最新 |

---

## 🎯 常用配置组合

### 组合 1: 小米 AX3000T (科学上网)

```
OpenWRT 源码：VIKINGYFY/immortalwrt
源码分支：main
目标平台：MEDIATEK

科学上网插件：homeproxy,openclash
插件版本：v1.9.5,v0.45.87

存储插件：diskman
网络工具：tailscale,ddns-go

UI 主题：argon
```

### 组合 2: NanoPi R4S (旁路由)

```
OpenWRT 源码：immortalwrt/immortalwrt
源码分支：owrt
目标平台：ROCKCHIP

科学上网插件：openclash,passwall
插件版本：v0.45.87,v2.8.3

网络工具：tailscale,easytier,vnt

UI 主题：aurora
```

### 组合 3: X86 (All in One)

```
OpenWRT 源码：VIKINGYFY/immortalwrt
源码分支：main
目标平台：X86

科学上网插件：homeproxy,openclash,passwall
插件版本：v1.9.5,v0.45.87,v2.8.3

存储插件：diskman,samba4,aria2,qbittorrent
网络工具：tailscale,ddns-go,easytier

UI 主题：argon

其他插件：lucky,vnt
```

### 组合 4: 360 T7 (广告过滤)

```
OpenWRT 源码：VIKINGYFY/immortalwrt
源码分支：main
目标平台：MEDIATEK

科学上网插件：homeproxy
插件版本：v1.9.5

网络工具：ddns-go

UI 主题：kucat

其他插件：luci-app-adblock,luci-app-oaf
```

---

## 🔧 高级选项

### 指定插件版本

**格式**: 插件名@版本号

```bash
# 示例
openclash@v0.45.87
passwall@v2.8.3
homeproxy@v1.9.5
```

### 使用测试版插件

```bash
# OpenClash dev 分支
git clone -b dev https://github.com/vernesong/OpenClash.git
```

### 自定义插件源

```bash
# 添加第三方插件源
echo "src-git custom https://github.com/your-repo/custom-plugins.git" >> feeds.conf.default
./scripts/feeds update custom
./scripts/feeds install -a
```

---

## 📊 编译选项

### 仅输出配置 (不编译)

勾选 **"仅输出配置，不编译固件"**

**用途**:
- 验证配置是否正确
- 生成配置文件供下载
- 测试插件兼容性

### 完整编译

不勾选测试模式

**输出**:
- 固件文件 (.bin/.img.gz)
- 配置文件 (.config)
- 校验和 (SHA256/MD5)
- 固件信息 (FIRMWARE_INFO.md)

---

## 📥 下载固件

### Releases 页面

访问：https://github.com/liuziqiang78-liu/OpenWRT-CI/releases

**查找**:
- `Custom-Build-平台名 - 日期时间`
- 包含所有固件和配置文件

### 验证固件

```bash
# 下载后验证
sha256sum -c SHA256SUMS.txt
md5sum -c MD5SUMS.txt
```

---

## ❓ 常见问题

### Q: 插件版本不存在怎么办？
**A**: 会自动安装最新版本，并在日志中提示

### Q: 可以安装多个科学插件吗？
**A**: 可以，但建议只启用一个，避免冲突

### Q: 编译需要多久？
**A**: 
- 首次编译：30-60 分钟
- 使用缓存：15-30 分钟

### Q: 如何分享我的配置？
**A**: 
1. 下载 `.config` 文件
2. 上传到 GitHub/Gist
3. 分享链接

### Q: 插件编译失败怎么办？
**A**: 
1. 检查插件仓库是否存在
2. 检查版本是否正确
3. 尝试使用最新版本
4. 查看编译日志

---

## 📚 相关文档

- [配置模块化指南](docs/CONFIG-MODULAR.md)
- [版本控制指南](docs/VERSION-CONTROL.md)
- [快速开始](QUICK-START.md)

---

*最后更新：2026-04-11*
