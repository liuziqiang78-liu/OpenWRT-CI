# 📤 推送监控配置到 GitHub

## 当前状态

✅ 本地文件已创建并提交
⏳ 等待推送到 GitHub 仓库

---

## 推送方法

### 方法 1: 使用 Git 命令行 (推荐)

在 OpenWRT-CI 目录执行：

```bash
cd /home/admin/openclaw/workspace/OpenWRT-CI

# 配置 Git 用户 (如果还没配置)
git config user.email "你的 GitHub 邮箱"
git config user.name "你的 GitHub 用户名"

# 推送到 GitHub
git push origin main
```

**需要认证** - 使用以下方式之一：
- GitHub Personal Access Token (PAT)
- SSH Key
- GitHub CLI

---

### 方法 2: 使用 GitHub Desktop

1. 打开 GitHub Desktop
2. 添加本地仓库：`/home/admin/openclaw/workspace/OpenWRT-CI`
3. 点击 "Push origin"

---

### 方法 3: 使用 GitHub CLI

```bash
# 安装 gh (如果未安装)
# Ubuntu/Debian:
sudo apt install gh

# 登录 GitHub
gh auth login

# 推送
cd /home/admin/openclaw/workspace/OpenWRT-CI
git push origin main
```

---

## 推送后验证

### 1. 检查文件是否上传成功

访问：https://github.com/liuziqiang78-liu/OpenWRT-CI

确认以下文件存在：
- `.github/workflows/Dependency-Monitor.yml`
- `Scripts/dependency-monitor.sh`
- `dependency-monitor/README.md`
- `dependency-monitor/USAGE.md`

### 2. 启用 GitHub Actions

1. 进入仓库 → **Actions** 标签
2. 找到 **"Dependency Monitor"** 工作流
3. 点击 **"Enable workflow"** (如果被禁用)

### 3. 手动触发第一次运行

1. Actions → Dependency Monitor
2. 点击 **"Run workflow"**
3. 选择分支 (main)
4. 点击 **"Run workflow"**

### 4. 查看运行结果

- 等待工作流完成 (约 2-5 分钟)
- 点击运行记录查看详细日志
- 下载 Artifacts 中的报告文件

---

## 配置说明

### 定时任务

工作流默认配置：
- **频率**: 每天早上 8:00 (UTC 时间 0:00)
- **时区**: UTC (北京时间 +8)

修改频率 (编辑 `.github/workflows/Dependency-Monitor.yml`):
```yaml
on:
  schedule:
    - cron: '0 0 * * *'  # 每天 UTC 0:00
```

### 通知设置

当发现严重问题时：
- 自动创建 GitHub Issue
- Issue 标题：`⚠️ 依赖仓库检查发现严重问题`
- 包含完整的监控报告

---

## 常见问题

### Q: 推送时提示认证失败
**A**: 使用 Personal Access Token:
1. GitHub → Settings → Developer settings → Personal access tokens
2. 生成新 Token (勾选 `repo` 权限)
3. 推送时使用 Token 作为密码

### Q: Actions 没有运行
**A**: 检查:
1. Actions 是否被启用
2. 仓库是否有 `.github/workflows/` 目录
3. 工作流文件语法是否正确

### Q: 如何更改监控频率
**A**: 编辑 `Dependency-Monitor.yml`:
```yaml
# 每天运行
- cron: '0 0 * * *'

# 每周运行 (周一 8:00)
- cron: '0 0 * * 1'

# 每 6 小时运行
- cron: '0 */6 * * *'
```

---

## 下一步

推送完成后，你可以：
1. ✅ 等待第一次自动运行 (或手动触发)
2. ✅ 查看监控报告
3. ✅ 根据报告调整依赖策略
4. ✅ 定期检查监控结果

---

*创建时间：2026-04-11*
