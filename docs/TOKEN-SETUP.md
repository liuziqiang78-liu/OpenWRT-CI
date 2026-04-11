# 🔑 GitHub Token 配置指南

---

## 🎯 为什么需要 Token？

Web UI 需要 GitHub Token 来调用 GitHub API，自动触发编译工作流。

---

## ✅ 创建 Token 步骤

### 步骤 1: 访问 Token 设置页面

打开：https://github.com/settings/tokens

---

### 步骤 2: 生成新 Token

点击 **"Generate new token"** → **"Generate new token (classic)"**

---

### 步骤 3: 填写 Token 信息

**Note (备注)**:
```
OpenWRT-CI Build UI
```

**Expiration (过期时间)**:
```
选择：No expiration (永不过期)
或者：Custom (自定义，建议至少 90 天)
```

---

### 步骤 4: 勾选权限 ⚠️

**必须勾选以下权限**:

```
✅ repo (Full control of private repositories)
✅ workflow (Configure GitHub Actions workflows)
```

**详细权限说明**:

| 权限 | 用途 | 必需 |
|------|------|------|
| **repo** | 访问仓库内容 | ✅ 必需 |
| **workflow** | 触发 GitHub Actions | ✅ 必需 |

---

### 步骤 5: 生成 Token

滚动到页面底部，点击 **"Generate token"**

---

### 步骤 6: 复制 Token

**重要**: Token 只会显示一次！

```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**立即复制**并保存到安全的地方（如密码管理器）

---

## 🔧 在 Web UI 中配置 Token

### 方法 1: 首次配置

1. 访问 Web UI: https://liuziqiang78-liu.github.io/OpenWRT-CI/build-ui.html
2. 找到 **"GitHub Token 配置"** 部分
3. 粘贴 Token: `ghp_xxxxxxxxxxxx`
4. Token 会自动保存到浏览器

### 方法 2: 更新 Token

1. 在 Token 输入框粘贴新 Token
2. 输入框失去焦点时自动保存

---

## 💾 Token 存储说明

### 存储位置
- **浏览器 LocalStorage**
- 仅保存在你的电脑
- **不会上传到任何服务器**
- 只有你能访问

### 安全性
- ✅ Token 存储在本地
- ✅ 使用 HTTPS 加密传输
- ✅ 只用于调用 GitHub API
- ✅ 不会分享给第三方

---

## 🔐 Token 权限说明

### repo 权限

允许：
- 访问仓库内容
- 读取仓库配置
- 管理 Releases

用于：
- 读取工作流文件
- 上传编译产物

### workflow 权限

允许：
- 触发 GitHub Actions 工作流
- 查看工作流运行状态
- 管理工作流运行

用于：
- 自动触发编译
- 查看编译进度

---

## ⚠️ 常见问题

### Q: Token 泄露了怎么办？

**A**: 立即删除并重新生成！

1. 访问：https://github.com/settings/tokens
2. 找到泄露的 Token
3. 点击 **"Delete"**
4. 重新生成新 Token
5. 更新 Web UI 中的配置

---

### Q: Token 过期了怎么办？

**A**: 重新生成即可

1. 删除过期 Token
2. 生成新 Token
3. 在 Web UI 中更新

---

### Q: 可以给 Token 设置过期时间吗？

**A**: 可以！

创建时选择：
- **30 天** - 短期使用
- **60 天** - 中期使用
- **90 天** - 推荐使用
- **Custom** - 自定义天数

---

### Q: Token 权限太大，不安全？

**A**: 可以创建细粒度 Token（Beta）

1. 访问：https://github.com/settings/personal-access-tokens
2. 点击 **"Generate new token"**
3. 选择仓库：`liuziqiang78-liu/OpenWRT-CI`
4. 设置权限：
   - Actions: Read and write
   - Contents: Read only

---

### Q: 多个设备如何使用？

**A**: 每个设备都需要配置

Token 存储在浏览器 LocalStorage，不同设备/浏览器需要分别配置。

---

## 🚀 使用流程

### 首次使用

```
创建 Token
    ↓
复制 Token
    ↓
访问 Web UI
    ↓
粘贴 Token
    ↓
选择配置
    ↓
开始编译
```

### 后续使用

```
访问 Web UI
    ↓
Token 已自动加载
    ↓
选择配置
    ↓
开始编译
```

---

## 📋 完整配置示例

### 1. 创建 Token

```
Note: OpenWRT-CI Build UI
Expiration: 90 days
Permissions: repo, workflow
```

### 2. 复制 Token

```
ghp_1A2B3C4D5E6F7G8H9I0J...
```

### 3. 粘贴到 Web UI

在 **"GitHub Token 配置"** 输入框粘贴

### 4. 开始使用

Token 会自动保存，下次访问无需重新输入

---

## 🔒 安全建议

### ✅ 推荐

- 设置 Token 过期时间（90 天）
- 使用密码管理器保存 Token
- 定期检查 Token 使用情况
- 不使用时删除 Token

### ❌ 避免

- 不要分享 Token 给他人
- 不要提交到代码仓库
- 不要发布到公开场合
- 不要使用过期 Token

---

## 📊 Token 使用监控

查看 Token 使用情况：

1. 访问：https://github.com/settings/tokens
2. 查看每个 Token 的 **"Last used"** 列
3. 可以看到最后使用时间

---

## 🎯 下一步

配置完 Token 后：

1. ✅ 在 Web UI 选择配置
2. ✅ 点击"开始编译"
3. ✅ 自动触发工作流
4. ✅ 查看编译进度
5. ✅ 下载固件

---

*最后更新：2026-04-11*
