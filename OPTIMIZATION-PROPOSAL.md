# OpenWRT-CI 优化建议报告

**分析时间**: 2026-04-11
**分析对象**: liuziqiang78-liu/OpenWRT-CI

---

## 🔍 核心问题分析

### 1. 插件版本控制缺失 ⚠️

**现状**:
- 所有插件使用**分支名**而非**固定版本号/Tag**
- 每次编译都拉取分支最新代码 (`master`, `main`)
- 仅 `sing-box` 有自动版本更新机制

**风险**:
```
❌ 上游更新可能导致编译失败
❌ 插件 API 变更导致不兼容
❌ 无法回退到稳定版本
❌ 固件行为不可预测 (今天能用，明天可能不能用)
```

**实际案例**:
- OpenClash dev 分支可能突然变更配置格式
- PassWall 可能更新依赖导致编译失败
- 主题插件可能变更 UI 结构

---

### 2. 建议方案：分层版本控制

#### 方案 A: 固定 Tag/Commit (推荐用于生产环境)

```bash
# 当前 (不稳定)
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"

# 改进后 (稳定)
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "v3.2.1"  # 固定 Tag
# 或
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "a1b2c3d"  # 固定 Commit
```

**优点**:
- ✅ 编译结果可重现
- ✅ 避免上游突然变更
- ✅ 可快速回退到已知稳定版本

**缺点**:
- ⚠️ 需要手动更新版本号
- ⚠️ 可能错过重要修复

---

#### 方案 B: 版本配置文件 (推荐)

创建 `Config/VERSIONS.txt`:

```bash
# 插件版本配置文件
# 格式：包名=仓库@分支@版本 (版本可选)

# 主题 - 使用固定版本
argon=sbwml/luci-theme-argon@openwrt-25.12@v3.2.1
aurora=eamonxg/luci-theme-aurora@master@v1.5.0

# 代理 - 使用稳定分支
openclash=vernesong/OpenClash@dev@latest  # 每次检查最新
passwall=Openwrt-Passwall/openwrt-passwall@main@v2.8.3

# 工具 - 使用最新
mosdns=sbwml/luci-app-mosdns@v5
tailscale=Tokisaki-Galaxy/luci-app-tailscale-community@master
```

配合脚本自动解析版本。

---

#### 方案 C: 混合模式 (最佳实践)

| 插件类型 | 策略 | 说明 |
|---------|------|------|
| **核心插件** (代理/科学) | 固定版本 | OpenClash, PassWall 等关键插件 |
| **主题** | 固定版本 | Argon, Aurora 等 UI 插件 |
| **工具类** | 分支最新 | 风扇控制，磁盘管理等 |
| **实验性** | 分支最新 | 新插件，待验证功能 |

---

### 3. 其他优化建议

#### 3.1 增加版本锁定文件

创建 `Config/LOCKED_VERSIONS.md`:

```markdown
# 当前编译使用的插件版本

| 插件 | 仓库 | 使用版本 | 锁定日期 | 状态 |
|------|------|----------|----------|------|
| OpenClash | vernesong/OpenClash | v0.45.87 | 2026-04-01 | ✅ 稳定 |
| Argon | sbwml/luci-theme-argon | v3.2.1 | 2026-03-15 | ✅ 稳定 |
| PassWall | Openwrt-Passwall/openwrt-passwall | v2.8.3 | 2026-04-05 | ✅ 稳定 |
| MosDNS | sbwml/luci-app-mosdns | v5.2.0 | 2026-03-20 | ✅ 稳定 |
```

**用途**:
- 记录当前生产环境使用的版本
- 方便回滚和故障排查
- 版本升级前对比

---

#### 3.2 增加版本更新工作流

创建 `.github/workflows/Version-Check.yml`:

```yaml
name: Check Plugin Updates

on:
  schedule:
    - cron: '0 6 * * *'  # 每天早上 2 点
  workflow_dispatch:

jobs:
  check-updates:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check for new releases
        run: |
          # 检查所有固定版本插件是否有新 Tag
          # 如果有，创建 PR 或 Issue 提醒
```

**功能**:
- 自动检查插件新版本
- 创建 Issue 提醒升级
- 可选：自动创建版本更新 PR

---

#### 3.3 增加编译前验证

在 `WRT-CORE.yml` 中增加验证步骤:

```yaml
- name: Validate Plugin Versions
  run: |
    # 检查关键插件版本是否兼容
    # 验证 Makefile 语法
    # 检查依赖关系
```

---

#### 3.4 增加回滚机制

**当前问题**: 新版本出问题无法快速回退

**解决方案**:
```bash
# 创建版本分支
git tag firmware-2026-04-11-stable
git branch stable/v2026-04

# 回滚脚本
Scripts/rollback.sh v2026-03  # 回退到 3 月版本
```

---

#### 3.5 优化缓存策略

**当前**: 缓存 key 仅包含配置名 + 源码 hash

**建议**: 增加插件版本到缓存 key
```yaml
key: ${{env.WRT_CONFIG}}-${{env.WRT_INFO}}-${{env.PLUGIN_HASH}}-${{env.WRT_HASH}}
```

避免插件更新后使用旧缓存导致版本不一致。

---

#### 3.6 增加插件健康检查

创建 `Scripts/plugin-health-check.sh`:

```bash
#!/bin/bash

# 检查插件仓库状态
# 检查分支是否存在
# 检查最后更新时间
# 检查是否有编译错误报告

PLUGINS=(
    "vernesong/OpenClash"
    "Openwrt-Passwall/openwrt-passwall"
    "sbwml/luci-theme-argon"
)

for plugin in "${PLUGINS[@]}"; do
    # 检查仓库状态
    # 检查 Issues 中的编译错误
    # 输出警告
done
```

---

#### 3.7 文档化插件配置

创建 `Config/PLUGINS.md`:

```markdown
# 插件配置说明

## 代理插件

### OpenClash
- 版本：v0.45.87
- 分支：dev
- 配置：./Config/openclash.config
- 注意事项：需要订阅转换

### PassWall
- 版本：v2.8.3
- 分支：main
- 配置：./Config/passwall.config

## 主题

### Argon
- 版本：v3.2.1
- 自定义配置：主题色 #31a1a1
```

---

## 📋 优先级建议

| 优先级 | 建议 | 工作量 | 影响 |
|-------|------|--------|------|
| **P0** | 固定核心插件版本 | 2 小时 | 🔴 高 |
| **P1** | 创建版本锁定文件 | 1 小时 | 🟡 中 |
| **P2** | 增加版本检查工作流 | 3 小时 | 🟡 中 |
| **P3** | 优化缓存策略 | 2 小时 | 🟢 低 |
| **P4** | 创建回滚机制 | 2 小时 | 🟢 低 |

---

## 🎯 立即可执行的改进

### 第一步：固定关键插件版本

编辑 `Scripts/Packages.sh`:

```bash
# 核心插件 - 固定到已知稳定版本
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "v0.45.87" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "v2.8.3" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "v1.5.2" "pkg"
UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "v1.9.5"

# 主题 - 固定版本
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "v3.2.1"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "v1.5.0"

# 工具 - 保持分支最新 (可接受风险)
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5"
UPDATE_PACKAGE "tailscale" "Tokisaki-Galaxy/luci-app-tailscale-community" "master"
```

### 第二步：创建版本记录

```bash
cat > Config/VERSIONS.txt << EOF
# OpenWRT-CI Plugin Versions
# Generated: 2026-04-11

# Core Plugins (Fixed)
OPENCLASH_VER=v0.45.87
PASSWALL_VER=v2.8.3
PASSWALL2_VER=v1.5.2
HOMESPROXY_VER=v1.9.5

# Themes (Fixed)
ARGON_VER=v3.2.1
AURORA_VER=v1.5.0

# Tools (Latest Branch)
MOSDNS_BRANCH=v5
TAILSCALE_BRANCH=master
EOF
```

---

## 💡 长期建议

1. **建立测试流程**: 新版本先在测试环境验证
2. **灰度发布**: 先编译少量设备，验证后再全量
3. **用户反馈渠道**: 收集固件使用问题
4. **自动化测试**: 编译后自动测试基本功能
5. **版本发布说明**: 每次发布记录变更内容

---

*报告生成：2026-04-11*
