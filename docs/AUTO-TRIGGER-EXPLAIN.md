# 🔧 Web UI 自动触发说明

---

## ⚠️ 当前状态

**问题**: Web UI 点击"开始编译"后没有自动触发编译

**原因**: 浏览器安全限制 + GitHub API 认证问题

---

## 📋 当前实现

### 点击"开始编译"后

1. ✅ 显示配置确认对话框
2. ✅ 打开 GitHub Actions 页面
3. ❌ **需要手动触发工作流**

---

## 🔧 为什么不能自动触发？

### 1. 浏览器安全限制

- 网页 JavaScript 无法直接调用 GitHub API
- 需要后端服务器代理
- CORS 跨域限制

### 2. GitHub API 认证

- 需要 Personal Access Token (PAT)
- Token 不能暴露在前端代码中
- 需要权限：`actions:write`

### 3. 安全考虑

- 防止未授权编译
- 避免滥用 GitHub Actions
- 保护用户 Token

---

## ✅ 解决方案

### 方案 1: 手动触发（当前）

**步骤**:

1. 在 Web UI 选择配置
2. 点击"开始编译"
3. 打开 GitHub Actions 页面
4. 选择 **Custom Build** 工作流
5. 点击 **Run workflow**
6. 填写配置（复制 Web UI 的配置）
7. 点击 **Run workflow** 开始编译

**优点**:
- ✅ 简单
- ✅ 安全
- ✅ 无需额外配置

**缺点**:
- ❌ 需要手动操作
- ❌ 配置需要填写两次

---

### 方案 2: 使用 GitHub CLI（推荐高级用户）

**步骤**:

1. **安装 GitHub CLI**:
   ```bash
   # macOS
   brew install gh
   
   # Linux
   sudo apt install gh
   
   # Windows
   winget install GitHub.cli
   ```

2. **登录 GitHub**:
   ```bash
   gh auth login
   ```

3. **触发工作流**:
   ```bash
   gh workflow run Custom-Build.yml \
     -f wrt_source=VIKINGYFY/immortalwrt \
     -f wrt_branch=main \
     -f target_platform=MEDIATEK \
     -f theme=argon \
     -f proxy_plugins=homeproxy,openclash \
     -f storage_plugins=diskman \
     -f network_plugins=tailscale,ddns-go
   ```

**优点**:
- ✅ 命令行自动化
- ✅ 可以写脚本
- ✅ 支持 CI/CD

**缺点**:
- ❌ 需要安装 CLI
- ❌ 需要命令行操作

---

### 方案 3: 创建 GitHub App（企业级）

**步骤**:

1. 创建 GitHub App
2. 配置权限：`actions:write`
3. 安装到仓库
4. 使用 App Token 调用 API
5. 后端服务接收 Web UI 请求
6. 后端调用 GitHub API 触发

**优点**:
- ✅ 完全自动化
- ✅ 用户体验好
- ✅ 安全可靠

**缺点**:
- ❌ 需要后端服务器
- ❌ 开发成本高
- ❌ 需要维护

---

### 方案 4: 使用 GitHub Actions Input 模板

**创建一个辅助工作流**:

```yaml
name: Trigger Custom Build

on:
  workflow_dispatch:
    inputs:
      config_json:
        description: 'JSON 配置'
        required: true

jobs:
  trigger:
    runs-on: ubuntu-latest
    steps:
      - name: Parse Config
        run: |
          echo "${{ inputs.config_json }}" | jq .
      
      - name: Trigger Build
        run: |
          # 解析 JSON 并触发实际编译
```

**Web UI 生成 JSON 配置**:
```javascript
const config = {
  wrt_source: "VIKINGYFY/immortalwrt",
  target_platform: "MEDIATEK",
  // ...
};

// 复制到剪贴板
navigator.clipboard.writeText(JSON.stringify(config));
```

**用户操作**:
1. Web UI 选择配置
2. 点击"复制配置"
3. 打开 GitHub Actions
4. 粘贴 JSON 配置
5. 触发编译

---

## 🎯 推荐方案

### 普通用户：方案 1（手动触发）

**流程**:
```
Web UI 选择配置
    ↓
查看配置摘要
    ↓
打开 GitHub Actions
    ↓
选择 Custom Build
    ↓
填写配置（参考 Web UI）
    ↓
开始编译
```

**提示**:
- Web UI 的配置摘要可以截图
- 在 GitHub Actions 页面照着填写
- 只需几分钟

---

### 高级用户：方案 2（GitHub CLI）

**创建快捷脚本**:
```bash
#!/bin/bash
# build.sh

gh workflow run Custom-Build.yml \
  -f wrt_source=$1 \
  -f target_platform=$2 \
  -f proxy_plugins=$3 \
  -f theme=$4

echo "编译已触发！"
```

**使用**:
```bash
./build.sh VIKINGYFY/immortalwrt MEDIATEK homeproxy argon
```

---

## 📱 Web UI 改进建议

### 当前版本

- ✅ 可视化选择配置
- ✅ 实时预览摘要
- ✅ 打开 Actions 页面
- ❌ 需要手动填写配置

### 未来版本

- ✅ 一键复制配置（JSON 格式）
- ✅ 直接跳转到 Custom Build 页面
- ✅ 配置自动填充（通过 URL 参数）
- ✅ 编译进度实时显示
- ✅ 完成通知

---

## 🔮 即将实现的功能

### 1. URL 参数传递

```
https://liuziqiang78-liu.github.io/OpenWRT-CI/build-ui.html?
  source=VIKINGYFY/immortalwrt&
  platform=MEDIATEK&
  plugins=homeproxy,openclash&
  theme=argon
```

**好处**:
- 可以保存常用配置
- 可以分享配置链接
- 自动填充表单

### 2. 配置模板

```javascript
const templates = {
  'xiaomi_ax3000t': {
    source: 'VIKINGYFY/immortalwrt',
    platform: 'MEDIATEK',
    plugins: ['homeproxy', 'tailscale'],
    theme: 'argon'
  },
  'nanopi_r4s': {
    source: 'immortalwrt/immortalwrt',
    platform: 'ROCKCHIP',
    plugins: ['openclash', 'easytier'],
    theme: 'aurora'
  }
};
```

**好处**:
- 一键选择预设配置
- 新手友好
- 减少错误

### 3. 配置导出/导入

```javascript
// 导出配置
const configBlob = new Blob([JSON.stringify(config)], {type: 'application/json'});
download(configBlob, 'my-config.json');

// 导入配置
const file = document.getElementById('config-file').files[0];
const config = JSON.parse(await file.text());
fillForm(config);
```

**好处**:
- 保存常用配置
- 分享配置给朋友
- 批量部署

---

## 📊 对比总结

| 方案 | 自动化程度 | 难度 | 推荐 |
|------|----------|------|------|
| **手动触发** | ⭐⭐ | ⭐ | ✅ 当前使用 |
| **GitHub CLI** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ 高级用户 |
| **GitHub App** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⏳ 未来版本 |
| **URL 参数** | ⭐⭐⭐ | ⭐⭐ | ⏳ 即将实现 |

---

## 🎯 当前最佳实践

### 步骤 1: 在 Web UI 选择配置

```
访问：https://liuziqiang78-liu.github.io/OpenWRT-CI/build-ui.html

选择：
- OpenWRT 源码：VIKINGYFY/immortalwrt
- 目标平台：MEDIATEK
- 科学插件：homeproxy, openclash
- 存储插件：diskman
- 网络工具：tailscale, ddns-go
- UI 主题：argon
```

### 步骤 2: 截图或记录配置

**截图配置摘要**，或者**拿纸笔记下来**

### 步骤 3: 打开 GitHub Actions

```
https://github.com/liuziqiang78-liu/OpenWRT-CI/actions
```

### 步骤 4: 选择 Custom Build

点击 **Custom Build** 工作流

### 步骤 5: 填写配置

**照着 Web UI 的配置填写**:
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

### 步骤 6: 开始编译

点击 **Run workflow**

---

## 💡 小贴士

### 1. 保存常用配置

创建一个文本文件保存配置：
```
# my-config.txt
源码：VIKINGYFY/immortalwrt@main
平台：MEDIATEK
插件：homeproxy v1.9.5, openclash v0.45.87
主题：argon
```

### 2. 使用浏览器书签

创建一个书签，直接打开 Custom Build 页面：
```
https://github.com/liuziqiang78-liu/OpenWRT-CI/actions/workflows/Custom-Build.yml
```

### 3. 编译进度查看

编译过程中可以：
- 查看实时日志
- 下载编译产物
- 接收完成通知（如果启用）

---

*最后更新：2026-04-11*
