# 🚀 快速开始 - 3 分钟完成配置

---

## ⚡ 最简单的方式 (推荐新手)

### 一键配置

```bash
cd OpenWRT-CI
bash Scripts/one-click.sh
```

**然后按提示操作即可！**

---

## 📋 常用配置速查

### 小米 AX3000T

```bash
# 科学上网 (推荐)
bash Scripts/config-builder.sh MEDIATEK xiaomi_ax3000t proxy

# 基础功能
bash Scripts/config-builder.sh MEDIATEK xiaomi_ax3000t basic

# 全部功能
bash Scripts/config-builder.sh MEDIATEK xiaomi_ax3000t full
```

---

### NanoPi R4S (旁路由)

```bash
# 旁路由推荐
bash Scripts/config-builder.sh ROCKCHIP nanopi_r4s proxy network-extra

# 基础旁路由
bash Scripts/config-builder.sh ROCKCHIP nanopi_r4s basic
```

---

### X86 (All in One)

```bash
# 完整功能
bash Scripts/config-builder.sh X86 generic full

# 游戏优化
bash Scripts/config-builder.sh X86 generic gaming
```

---

### 360 T7

```bash
# 广告过滤
bash Scripts/config-builder.sh MEDIATEK 360_t7 adblock

# 科学上网
bash Scripts/config-builder.sh MEDIATEK 360_t7 proxy
```

---

## 🎯 功能说明

| 模板 | 包含功能 | 适合场景 |
|------|----------|----------|
| **basic** | 基础网络 + WiFi | 纯路由，不需要额外功能 |
| **proxy** | 基础 + 科学上网 | 需要代理功能 (推荐) |
| **adblock** | 基础 + 广告过滤 | 去广告需求 |
| **nas** | 基础 + 存储管理 | NAS/下载服务器 |
| **gaming** | 基础 + 游戏优化 | 低延迟需求 |
| **full** | 所有功能 | 高级用户/All in One |

---

## 📖 详细配置

### 使用交互式向导

```bash
bash Scripts/config-wizard.sh
```

**步骤**:
1. 选择平台 (MEDIATEK/ROCKCHIP/X86/QUALCOMMAX)
2. 选择设备 (小米/360/NanoPi 等)
3. 选择功能 (基础/科学/广告/NAS/游戏/全部)
4. 自动生成配置

---

### 手动组合配置

```bash
# 平台 + 设备 + 功能
bash Scripts/config-builder.sh <平台> <设备> [功能...]

# 示例
bash Scripts/config-builder.sh MEDIATEK xiaomi_ax3000t proxy theme
```

---

## ✅ 配置完成后

### 1. 检查配置

```bash
cat Config/CUSTOM.txt
```

### 2. 提交配置

```bash
git add -A
git commit -m "chore: update config"
git push
```

### 3. 开始编译

1. 访问：https://github.com/liuziqiang78-liu/OpenWRT-CI/actions
2. 点击：**WRT-TEST**
3. 点击：**Run workflow**
4. 选择：**CUSTOM**
5. 点击：**Run workflow**

### 4. 下载固件

编译完成后：
1. 进入 **Releases**
2. 下载对应设备固件
3. 校验 SHA256/MD5
4. 刷入设备

---

## 🔧 高级选项

### 自定义模板

创建 `Config/templates/mycustom.txt`:

```bash
# 我的自定义配置
proxy
theme

# 特殊配置
CONFIG_PACKAGE_xxx=y
```

使用:
```bash
bash Scripts/config-builder.sh MEDIATEK xiaomi_ax3000t mycustom
```

---

### 配置验证

```bash
# 验证配置是否正确
bash Scripts/validate-config.sh

# 预览配置信息
bash Scripts/config-preview.sh
```

---

## ❓ 常见问题

### Q: 不知道选什么功能？
**A**: 新手推荐 `proxy` (科学上网)，包含基础功能 + 代理

### Q: 配置错了怎么办？
**A**: 重新运行 `bash Scripts/one-click.sh` 即可

### Q: 编译需要多久？
**A**: 首次约 2-3 小时，使用缓存后约 30-60 分钟

### Q: 如何分享我的配置？
**A**: 将 `Config/CUSTOM.txt` 提交到 GitHub 即可

---

## 📞 需要帮助？

- 📖 [配置模块化指南](docs/CONFIG-MODULAR.md)
- 📖 [版本控制指南](docs/VERSION-CONTROL.md)
- 📖 [故障排查](docs/TROUBLESHOOTING.md)
- 💬 提交 Issue

---

*最后更新：2026-04-11*
