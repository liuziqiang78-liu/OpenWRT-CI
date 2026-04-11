# 🔧 启用 GitHub Pages 步骤

---

## ❌ 当前状态

Web UI 已经创建，但 GitHub Pages 还没有启用，所以访问会显示 404。

---

## ✅ 启用步骤

### 步骤 1: 访问仓库设置

打开：https://github.com/liuziqiang78-liu/OpenWRT-CI/settings/pages

---

### 步骤 2: 配置 GitHub Pages

在 **Build and deployment** 部分：

1. **Source**: 选择 `Deploy from a branch`
2. **Branch**: 选择 `main`
3. **Folder**: 选择 `/ (root)`
4. 点击 **Save**

---

### 步骤 3: 等待部署

等待 1-2 分钟，GitHub 会自动部署页面。

部署完成后会显示：
```
Your site is live at https://liuziqiang78-liu.github.io/OpenWRT-CI/
```

---

### 步骤 4: 访问 Web UI

访问：
```
https://liuziqiang78-liu.github.io/OpenWRT-CI/build-ui.html
```

---

## 🚀 快速部署（可选）

### 手动触发部署工作流

1. 访问：https://github.com/liuziqiang78-liu/OpenWRT-CI/actions/workflows/Deploy-UI.yml
2. 点击 **Run workflow**
3. 选择 `main` 分支
4. 点击 **Run workflow**
5. 等待部署完成

---

## 📱 替代访问方式

如果 GitHub Pages 启用有问题，可以用以下方式访问：

### 方式 1: 本地打开

```bash
# 下载 build-ui.html 文件后
# 直接双击打开
open build-ui.html

# 或在浏览器中
file:///path/to/build-ui.html
```

### 方式 2: 使用 Python 简易服务器

```bash
# 在仓库目录
python3 -m http.server 8080

# 访问
http://localhost:8080/build-ui.html
```

### 方式 3: 使用 VS Code Live Server

1. 安装 VS Code
2. 安装 Live Server 插件
3. 右键 build-ui.html → Open with Live Server

---

## ⚠️ 常见问题

### Q: 设置页面 404？
**A**: 确保你是仓库管理员

### Q: 部署后还是 404？
**A**: 等待几分钟，GitHub 需要时间部署

### Q: 文件名大小写问题？
**A**: GitHub Pages 区分大小写，确保 URL 完全匹配

### Q: 自定义域名？
**A**: 可以在 Pages 设置中配置自定义域名

---

## 📊 部署状态

查看部署状态：
https://github.com/liuziqiang78-liu/OpenWRT-CI/deployments/github-pages

---

## 🎯 完成后的效果

启用后，用户可以：

1. 访问漂亮的 Web UI 界面
2. 可视化选择插件和版本
3. 实时预览配置
4. 一键触发编译

---

*创建时间：2026-04-11*
