# 🎨 Web UI 使用指南

---

## 🌐 访问 Web UI

### 方式 1: GitHub Pages (推荐)

**URL**: https://liuziqiang78-liu.github.io/OpenWRT-CI/build-ui.html

（需要先在仓库设置中启用 GitHub Pages）

### 方式 2: 本地打开

```bash
# 下载文件后
open build-ui.html

# 或在浏览器中打开
file:///path/to/build-ui.html
```

### 方式 3: 使用 Python 简易服务器

```bash
# Python 3
python3 -m http.server 8080

# 访问 http://localhost:8080/build-ui.html
```

---

## 🎯 功能说明

### 1. OpenWRT 源码选择

**可选源码**:
- ✅ VIKINGYFY/immortalwrt (推荐)
- ✅ immortalwrt/immortalwrt (官方)
- ✅ LiBwrt/openwrt-6.x (6.x 内核)
- ✅ qosmio/openwrt-ipq (高通优化)

**可选分支**:
- main
- owrt
- master

---

### 2. 目标平台选择

**平台分类**:

| 平台 | 设备 |
|------|------|
| **MEDIATEK** | 小米/360/京东云等 |
| **ROCKCHIP** | NanoPi/香橙派等 |
| **X86** | PC/虚拟机 |
| **IPQ60XX** | 高通 (带/不带 WiFi) |
| **IPQ50XX** | 高通 (带 WiFi) |
| **IPQ807X** | 高通 (带 WiFi) |

---

### 3. 插件选择

#### 科学上网插件 (4 个)

| 插件 | 推荐版本 | 说明 |
|------|----------|------|
| HomeProxy | v1.9.5 | 🏠 推荐新手 |
| OpenClash | v0.45.87 | ⚡ 功能强大 |
| PassWall | v2.8.3 | 🌐 稳定 |
| PassWall2 | v1.5.2 | 🌐 新版 |

#### 存储管理插件 (4 个)

| 插件 | 推荐版本 | 说明 |
|------|----------|------|
| DiskMan | v0.5.0 | 💾 磁盘管理 |
| Samba4 | 内置 | 📁 文件共享 |
| Aria2 | 最新 | ⬇️ 下载工具 |
| Qbittorrent | 最新 | 📥 BT 下载 |

#### 网络工具 (4 个)

| 插件 | 说明 |
|------|------|
| Tailscale | 🔒 内网穿透 |
| DDNS-GO | 🌍 动态 DNS |
| EasyTier | 🚀 组网工具 |
| VNT | 🔗 虚拟网络 |

#### UI 主题 (4 个)

| 主题 | 说明 |
|------|------|
| Argon | 🎨 推荐 (默认) |
| Aurora | 🌅 极光 |
| Kucat | 🐱 可爱 |
| none | ⚪ 默认 |

---

## 📋 使用步骤

### 步骤 1: 访问 UI 页面

打开浏览器，访问：
```
https://liuziqiang78-liu.github.io/OpenWRT-CI/build-ui.html
```

### 步骤 2: 选择配置

1. **选择 OpenWRT 源码**
2. **选择目标平台**
3. **勾选需要的插件**
4. **指定插件版本** (可选)
5. **选择 UI 主题**

### 步骤 3: 查看配置摘要

页面底部会实时显示你选择的配置：

```
源码：VIKINGYFY/immortalwrt
平台：MEDIATEK
主题：Argon

科学插件：[homeproxy] [openclash]
存储插件：[diskman]
网络工具：[tailscale]
```

### 步骤 4: 开始编译

点击 **"🚀 开始编译"** 按钮

**当前版本**: 会打开 GitHub Actions 页面，手动触发

**未来版本**: 将支持自动触发

---

## 🎨 UI 特性

### 响应式设计
- ✅ 支持手机/平板/电脑
- ✅ 自适应屏幕尺寸

### 实时预览
- ✅ 选择插件时实时显示摘要
- ✅ 版本信息一目了然

### 友好交互
- ✅ 点击卡片选择插件
- ✅ 颜色区分选中状态
- ✅ 工具提示和说明

---

## 💡 常用配置示例

### 示例 1: 小米 AX3000T (科学上网)

```
源码：VIKINGYFY/immortalwrt@main
平台：MEDIATEK
主题：Argon

科学插件：HomeProxy v1.9.5, OpenClash v0.45.87
存储插件：DiskMan
网络工具：Tailscale, DDNS-GO
```

### 示例 2: NanoPi R4S (旁路由)

```
源码：immortalwrt/immortalwrt@owrt
平台：ROCKCHIP
主题：Aurora

科学插件：OpenClash v0.45.87
网络工具：Tailscale, EasyTier, VNT
```

### 示例 3: X86 (All in One)

```
源码：VIKINGYFY/immortalwrt@main
平台：X86
主题：Argon

科学插件：HomeProxy, OpenClash, PassWall
存储插件：DiskMan, Samba4, Aria2, Qbittorrent
网络工具：Tailscale, DDNS-GO, EasyTier
其他插件：lucky, vlmcsd
```

---

## 🔧 启用 GitHub Pages

### 步骤 1: 访问设置

https://github.com/liuziqiang78-liu/OpenWRT-CI/settings/pages

### 步骤 2: 配置来源

- **Source**: Deploy from a branch
- **Branch**: main
- **Folder**: / (root)

### 步骤 3: 保存

等待部署完成 (约 1-2 分钟)

### 步骤 4: 访问

```
https://liuziqiang78-liu.github.io/OpenWRT-CI/build-ui.html
```

---

## 🚀 自动触发 (未来功能)

### 当前版本

点击"开始编译"后会：
1. 打开 GitHub Actions 页面
2. 手动填写配置
3. 触发工作流

### 未来版本

将支持：
1. ✅ 自动填写配置
2. ✅ 一键触发工作流
3. ✅ 编译进度实时显示
4. ✅ 完成通知

---

## 📱 移动端适配

UI 已针对移动端优化：

- ✅ 触摸友好的大按钮
- ✅ 自适应网格布局
- ✅ 清晰的字体和颜色
- ✅ 简化的操作流程

---

## 🎯 优势对比

| 功能 | 传统方式 | Web UI |
|------|----------|--------|
| **配置难度** | ⭐⭐ (需要看文档) | ⭐⭐⭐⭐⭐ (可视化) |
| **版本选择** | ❌ (手动查找) | ✅ (下拉选择) |
| **插件预览** | ❌ (不知道有哪些) | ✅ (卡片展示) |
| **配置验证** | ❌ (编译才知道) | ✅ (实时预览) |
| **用户体验** | ⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 📚 相关文档

- [自定义构建指南](docs/CUSTOM-BUILD.md)
- [配置模块化指南](docs/CONFIG-MODULAR.md)
- [快速开始](QUICK-START.md)

---

*最后更新：2026-04-11*
