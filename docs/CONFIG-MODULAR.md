# 配置模块化使用指南

---

## 📁 目录结构

```
Config/
├── base/                    # 基础配置模块
│   ├── network.txt          # 网络配置
│   ├── wifi.txt             # WiFi 配置
│   ├── packages.txt         # 基础软件包
│   ├── proxy.txt            # 代理插件 (可选)
│   ├── adblock.txt          # 广告过滤 (可选)
│   ├── storage.txt          # 存储管理 (可选)
│   ├── network-extra.txt    # 网络增强 (可选)
│   └── theme.txt            # 主题配置 (可选)
├── platform/                # 平台配置
│   ├── MEDIATEK.txt         # 联发科平台
│   ├── ROCKCHIP.txt         # 瑞芯微平台
│   ├── X86.txt              # X86 平台
│   └── QUALCOMMAX.txt       # 高通平台
├── device/                  # 设备配置
│   ├── xiaomi_ax3000t.txt   # 小米 AX3000T
│   ├── 360_t7.txt           # 360 T7
│   ├── nanopi_r4s.txt       # NanoPi R4S
│   └── ...
├── templates/               # 配置模板
│   ├── basic.txt            # 基础模板
│   ├── full.txt             # 完整模板
│   ├── gaming.txt           # 游戏优化
│   ├── adblock.txt          # 广告过滤
│   └── nas.txt              # NAS 模板
├── generated/               # 生成的配置 (自动)
└── GENERAL.txt              # 通用配置
```

---

## 🚀 快速开始

### 方法 1: 使用配置组合工具 (推荐)

```bash
cd OpenWRT-CI

# 语法
bash Scripts/config-builder.sh <平台> <设备> [模板...]

# 示例 1: 小米 AX3000T + 完整功能
bash Scripts/config-builder.sh MEDIATEK xiaomi_ax3000t full

# 示例 2: NanoPi R4S + 基础 + 代理
bash Scripts/config-builder.sh ROCKCHIP nanopi_r4s proxy

# 示例 3: X86 + 游戏优化
bash Scripts/config-builder.sh X86 generic gaming
```

**输出**: `Config/generated/MEDIATEK_xiaomi_ax3000t_YYYYMMDD_HHMMSS.txt`

**使用**:
```bash
# 复制生成的配置
cp Config/generated/*.txt Config/CUSTOM.txt

# 手动编译
Actions → WRT-TEST → Run workflow
选择配置：CUSTOM
```

---

### 方法 2: 手动组合

```bash
# 1. 选择平台配置
cat Config/platform/MEDIATEK.txt > Config/CUSTOM.txt

# 2. 添加设备配置
cat Config/device/xiaomi_ax3000t.txt >> Config/CUSTOM.txt

# 3. 添加基础配置
cat Config/base/network.txt >> Config/CUSTOM.txt
cat Config/base/wifi.txt >> Config/CUSTOM.txt
cat Config/base/packages.txt >> Config/CUSTOM.txt

# 4. 添加可选模板
cat Config/base/proxy.txt >> Config/CUSTOM.txt
cat Config/base/theme.txt >> Config/CUSTOM.txt

# 5. 添加通用配置
cat Config/GENERAL.txt >> Config/CUSTOM.txt
```

---

## 📋 配置模板说明

### basic (基础)
- 仅包含必要功能
- 适合新手
- 固件体积小

### full (完整)
- 包含所有功能
- 代理 + 存储 + 网络增强 + 主题
- 适合高级用户

### gaming (游戏优化)
- 网络增强
- SQM QoS
- 低延迟优化

### adblock (广告过滤)
- AdGuard Home
- Adblock
- 广告过滤优化

### nas (下载服务器)
- 存储管理
- Aria2 + Qbittorrent
- Samba 共享

---

## 🎯 常用组合

### 小米 AX3000T (科学上网)
```bash
bash Scripts/config-builder.sh MEDIATEK xiaomi_ax3000t proxy theme
```

### NanoPi R4S (旁路由)
```bash
bash Scripts/config-builder.sh ROCKCHIP nanopi_r4s proxy network-extra
```

### X86 (All in One)
```bash
bash Scripts/config-builder.sh X86 generic full
```

### 360 T7 (广告过滤)
```bash
bash Scripts/config-builder.sh MEDIATEK 360_t7 adblock
```

---

## 🔧 自定义配置

### 创建自定义模板

```bash
# 创建模板文件
cat > Config/templates/mycustom.txt << 'EOF'
proxy
storage
theme

# 自定义配置
CONFIG_PACKAGE_luci-app-xxx=y
EOF

# 使用自定义模板
bash Scripts/config-builder.sh MEDIATEK xiaomi_ax3000t mycustom
```

---

## 📊 配置检查

### 验证配置

```bash
# 检查语法
grep -E "^CONFIG_|^#|^$" Config/CUSTOM.txt

# 检查冲突
bash Scripts/config-diff.sh CUSTOM GENERAL
```

### 查看已选插件

```bash
grep "CONFIG_PACKAGE_" Config/CUSTOM.txt | grep "=y" | wc -l
```

---

## 💡 最佳实践

### ✅ 推荐

1. **使用模板**: 快速组合配置
2. **版本控制**: 保存自定义配置到 Git
3. **命名规范**: 使用有意义的文件名
4. **测试编译**: 先测试再全量编译
5. **文档化**: 记录配置选择理由

### ❌ 避免

1. **重复配置**: 同一插件不要多次启用
2. **冲突插件**: 如同时启用多个代理
3. **过度定制**: 保持配置简洁
4. **忽略测试**: 直接编译大版本

---

## 📝 示例配置

### 示例 1: 小米 AX3000T (科学 + 广告过滤)

```bash
bash Scripts/config-builder.sh MEDIATEK xiaomi_ax3000t proxy adblock theme
```

**包含**:
- HomeProxy / PassWall
- AdGuard Home
- Argon 主题
- 基础网络 + WiFi

### 示例 2: NanoPi R4S (旁路由)

```bash
bash Scripts/config-builder.sh ROCKCHIP nanopi_r4s proxy network-extra
```

**包含**:
- OpenClash
- Tailscale / EasyTier
- DDNS
- 基础网络

### 示例 3: X86 (All in One)

```bash
bash Scripts/config-builder.sh X86 generic full
```

**包含**:
- 所有代理插件
- 存储管理 (Samba/Aria2)
- Docker
- 网络增强
- 多主题

---

## 🔗 相关文档

- [固件命名规范](FIRMWARE-NAMING.md)
- [版本控制指南](VERSION-CONTROL.md)
- [故障排查](TROUBLESHOOTING.md)

---

*最后更新：2026-04-11*
