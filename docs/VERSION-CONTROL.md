# OpenWRT-CI 版本控制使用指南

---

## 📋 概述

本系统提供完整的插件版本管理解决方案，包括：

- **版本配置** - 集中管理所有插件版本
- **版本检查** - 自动检查可更新插件
- **版本更新** - 批量更新到最新版本
- **自动监控** - GitHub Actions 每日检查

---

## 📁 文件结构

```
OpenWRT-CI/
├── Config/
│   └── VERSIONS.txt              # 插件版本配置文件
├── Scripts/
│   ├── version-check.sh          # 版本检查工具
│   ├── version-update.sh         # 版本更新工具
│   └── Packages.sh               # 插件安装脚本 (需同步更新)
├── .github/workflows/
│   └── Plugin-Version-Check.yml  # 自动检查工作流
└── docs/
    └── VERSION-CONTROL.md        # 本文档
```

---

## 🚀 快速开始

### 1. 查看当前版本配置

```bash
cd OpenWRT-CI
cat Config/VERSIONS.txt
```

### 2. 检查可更新的插件

**本地运行**:
```bash
bash Scripts/version-check.sh
```

**输出示例**:
```
========================================
  OpenWRT-CI 插件版本检查
========================================

Checking: PROXY_OPENCLASH (vernesong/OpenClash@dev)
  当前：v0.45.87
  最新：v0.45.89
  📦 有新版本：v0.45.89

Checking: THEME_ARGON (sbwml/luci-theme-argon@openwrt-25.12)
  当前：v3.2.1
  最新：v3.2.1
  ✅ 已是最新

========================================
  统计摘要
========================================
  总插件数：32
  最新/活跃：28
  可更新：4
  错误：0
```

### 3. 更新插件版本

**试运行 (不实际修改)**:
```bash
bash Scripts/version-update.sh --dry-run
```

**更新所有插件到最新 Tag**:
```bash
bash Scripts/version-update.sh --mode fixed
```

**更新指定插件**:
```bash
bash Scripts/version-update.sh --plugin OPENCLASH --mode fixed
```

**使用分支最新 (不固定版本)**:
```bash
bash Scripts/version-update.sh --mode branch
```

### 4. 查看变更

```bash
git diff Config/VERSIONS.txt
```

### 5. 同步到 Packages.sh

手动更新 `Scripts/Packages.sh` 中的版本:

```bash
# 修改前
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"

# 修改后 (固定版本)
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "v0.45.89" "pkg"
```

### 6. 测试并提交

```bash
# 测试编译 (可选)
# 提交变更
git add -A
git commit -m "chore: update plugins to latest versions"
git push origin main
```

---

## 📊 版本策略

### 配置文件格式

```bash
# 格式：NAME=REPO@BRANCH@VERSION
# VERSION 可选，留空表示使用分支最新

# 固定版本 (推荐用于核心插件)
PROXY_OPENCLASH=vernesong/OpenClash@dev@v0.45.89

# 使用分支最新 (工具类插件)
NET_TAILSCALE=Tokisaki-Galaxy/luci-app-tailscale-community@master
```

### 版本选择建议

| 插件类型 | 策略 | 示例 |
|---------|------|------|
| **代理/科学** | 固定 Tag | `OpenClash@v0.45.89` |
| **主题** | 固定 Tag | `argon@v3.2.1` |
| **核心工具** | 固定 Tag | `mosdns@v5.2.0` |
| **小工具** | 分支最新 | `fancontrol@main` |
| **实验性** | 分支最新 | `newplugin@master` |

---

## 🤖 自动监控

### GitHub Actions 工作流

**Plugin-Version-Check.yml** 会:

1. **每天早上 7 点** 自动运行
2. 检查所有插件的最新版本
3. 生成详细报告
4. 如果有更新，**自动创建 Issue**

### 手动触发

1. 进入仓库 → **Actions** → **Plugin Version Check**
2. 点击 **Run workflow**
3. 选择模式:
   - `check`: 仅检查，创建 Issue 提醒
   - `update`: 检查并创建 PR (需额外配置)

### 查看报告

工作流完成后:
1. 点击运行记录
2. 下载 **Artifacts** 中的报告
3. 查看 `plugin-versions-report.md`

---

## 🔄 版本管理流程

### 常规更新流程

```
1. 运行版本检查
   bash Scripts/version-check.sh

2. 查看可更新插件
   检查输出，确定要更新的插件

3. 执行更新
   bash Scripts/version-update.sh --mode fixed

4. 验证变更
   git diff Config/VERSIONS.txt

5. 同步 Packages.sh
   手动更新 Packages.sh 中的版本

6. 测试编译 (推荐)
   触发一次测试编译，确保兼容

7. 提交变更
   git add -A && git commit -m "chore: update plugins"
   git push
```

### 紧急回滚流程

如果新版本有问题:

```bash
# 1. 找到上次正常的提交
git log --oneline Config/VERSIONS.txt

# 2. 恢复旧版本
git checkout <commit-hash> -- Config/VERSIONS.txt
git checkout <commit-hash> -- Scripts/Packages.sh

# 3. 重新编译
# 触发编译工作流

# 4. 提交回滚
git commit -m "revert: rollback to stable versions"
git push
```

---

## 📝 最佳实践

### ✅ 推荐做法

1. **核心插件固定版本**
   - OpenClash, PassWall 等关键插件
   - 避免上游突然变更导致编译失败

2. **更新前测试**
   - 先用 `--dry-run` 查看变更
   - 测试编译验证兼容性

3. **记录版本变更**
   - 在 commit message 中说明更新内容
   - 重要更新创建 Release Notes

4. **定期更新**
   - 每周检查一次版本
   - 安全更新及时应用

### ❌ 避免的做法

1. **全部使用分支最新**
   - 编译结果不可重现
   - 上游变更可能导致失败

2. **跳过测试直接发布**
   - 新版本可能有兼容性问题
   - 先测试再全量发布

3. **不同步 Packages.sh**
   - VERSIONS.txt 和 Packages.sh 必须一致
   - 否则编译会使用错误版本

---

## 🛠️ 高级用法

### 自定义版本检查脚本

```bash
# 只检查特定类别
bash Scripts/version-check.sh | grep "PROXY_"

# 导出为 JSON
bash Scripts/version-check.sh --json > versions.json

# 定期检查 (每小时)
watch -n 3600 bash Scripts/version-check.sh
```

### 批量更新特定类别

```bash
# 只更新代理插件
for plugin in PROXY_OPENCLASH PROXY_PASSWALL PROXY_HOMESPROXY; do
  bash Scripts/version-update.sh --plugin $plugin --mode fixed
done

# 只更新主题
for plugin in THEME_@*; do
  bash Scripts/version-update.sh --plugin $plugin --mode fixed
done
```

### 创建版本基线

```bash
# 保存当前版本为基线
cp Config/VERSIONS.txt Config/VERSIONS.baseline.2026-04-11.txt

# 对比变更
diff Config/VERSIONS.baseline.2026-04-11.txt Config/VERSIONS.txt
```

---

## 📋 检查清单

### 每次更新前

- [ ] 运行 `version-check.sh` 查看可更新插件
- [ ] 阅读上游 Release Notes (如果有)
- [ ] 确认更新范围 (全部/部分插件)
- [ ] 备份当前配置

### 每次更新后

- [ ] 同步 Packages.sh
- [ ] 运行测试编译
- [ ] 验证固件功能
- [ ] 提交变更并推送
- [ ] 更新版本文档

---

## 🔗 相关资源

- [优化建议文档](../OPTIMIZATION-PROPOSAL.md)
- [依赖监控文档](../dependency-monitor/README.md)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

---

*最后更新：2026-04-11*
